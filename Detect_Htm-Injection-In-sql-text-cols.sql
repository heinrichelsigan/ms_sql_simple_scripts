Set TRANSACTION ISOLATION LEVEL read uncommitted; 
GO

Declare @maxl int = 1, @test nvarchar(max) = '0', @cnt int = 0;
Select @maxl = Max(Col_Length(T.name, c.name)) from sys.tables T
Inner Join sys.columns c On  c.object_id = T.object_id 
Inner Join sys.types st On st.system_type_id = c.system_type_id
	And st.name In ('varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext')	    

WHILE len(@test) < @maxl + 8
BEGIN TRY
	Select @test = Cast(@cnt As nvarchar(max)) + IsNull(@test, '0')
	Set @cnt = @cnt + 1;
END TRY 
BEGIN CATCH 
END CATCH 
if (len(@test) < @maxl) 
BEGIN 
	Declare @mxlen int = len(@test);
	RAISERROR('Execution of script aborted, cause lenght of nvarchar(max)=%d < @maxl=%d', 43, 1, @mxlen, @maxl);
	RETURN;
END
Print 'Lenght of nvarchar(max)='  +  Cast(len(@test) as nvarchar) + ' > as @maxl=' + Cast(@maxl as nvarchar)


If Exists (Select Top 1 object_id From tempdb.sys.tables Where name = '##injWatch') 
    Delete From ##injWatch 
Else Create Table ##injWatch ( 
	ctext nvarchar(max), tab varchar(768), col varchar(768), systyp varchar(32), maxlen int);
GO

Declare ChckHinjCrsr Cursor FAST_FORWARD READ_ONLY For 
	Select st.name As sys_type,		
		'CAST([' + c.name + '] AS NVARCHAR(MAX))' As c_cast, 
		'' + s.name + '.[' +T.name + ']' As sT_name,
		c.name As colname,				
		c.max_length as colmaxl
	From sys.schemas s 
	Inner Join sys.tables T 
		On s.schema_id = T.schema_id
	Inner Join sys.columns c
		On  c.object_id = T.object_id 
		And c.max_length > 16
	Inner Join sys.types st 
		On st.system_type_id = c.system_type_id
		And st.name In ('varchar', 'nvarchar', 'char', 'nchar', 'text', 'ntext')	    
	Order by s.name, c.max_length desc, t.name, st.system_type_id

Declare @sys_type varchar(32), @c_cast varchar(1024), @sT_name varchar(768), @colname varchar(768), @colmaxl varchar(8)
Open ChckHinjCrsr 
Fetch Next From ChckHinjCrsr Into @sys_type, @c_cast, @sT_name, @colname, @colmaxl

While (@@FETCH_STATUS = 0) 
Begin 
  Declare @execSQL nvarchar(max) 
  Set @execSQL = 'INSERT INTO ##injWatch (ctext, tab, col, systyp, maxlen) ' + 
    'SELECT ' + @c_cast + ' As ctext, ''' + @sT_name + ''' As tab, ''' + @colname + ''' As col, ''' + @sys_type + ''' As systyp, Cast(''' + @colmaxl + ''' As int) As maxlen ' +
    'FROM ' + @sT_name + ' WITH (nolock) ' +
    'WHERE ' +  '(' + @c_cast + ' LIKE ''%<%'' AND ' + @c_cast + ' LIKE ''%>%'') ' +
		' OR ' + @c_cast + ' LIKE ''%mailto:%''' + ' OR ' + @c_cast + ' LIKE ''%href%'''  +
		' OR ' + @c_cast + ' LIKE ''%script:%''' + ' OR ' + @c_cast + ' LIKE ''%://%'''
		-- ' OR ' + @c_cast + ' LIKE ''%return %''' *
  Execute sp_executesql @execSQL; 
  Fetch Next From ChckHinjCrsr Into @sys_type, @c_cast, @sT_name, @colname, @colmaxl
End 
Close ChckHinjCrsr 
Deallocate ChckHinjCrsr 

Select Distinct * From ##InjWatch 
GO
					     
