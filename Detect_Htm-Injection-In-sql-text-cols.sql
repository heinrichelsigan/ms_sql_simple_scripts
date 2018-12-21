-- simplest prototype: Detect html & script injection in char based columns of SQL server
If Exists(Select Top 1 object_id From tempdb.sys.tables Where name = '##InjWatch')
	Delete From ##InjWatch
Else
	Create Table ##InjWatch ( ctext nvarchar(Max), tab varchar(768), col varchar(768));
GO 

Set TRANSACTION ISOLATION LEVEL read uncommitted; 

Declare InjectCursor Cursor
	FAST_FORWARD READ_ONLY For 
	Select c.name as c_name,
		'Cast([' + c.name + '] as nvarchar(max))' as c_cast,		 
		'' + s.name + '.[' +T.name + ']' as sT_name
	From sys.schemas s
	Inner Join sys.tables T
		On	T.schema_id = s.schema_id
	Inner Join sys.columns c
		On  c.object_id = T.object_id
		and c.max_length > 16 
	Where c.system_type_id In (
		Select system_type_id 
		From sys.types 
		Where name In (
			'varchar', 
			'nvarchar', 
			'char', 
			'nchar', 
			'text', 
			'ntext'))

Declare @colname varchar(768),
		@c_cast varchar(1024), 		
		@sT_name varchar(768)

Open InjectCursor
Fetch Next From InjectCursor 
	Into @colname, @c_cast, @sT_name

While (@@FETCH_STATUS = 0)
Begin
  Declare @execSQL nvarchar(max)
  Set @execSQL = 
	'insert into ##InjWatch (ctext, tab, col) '+
    'select ' + @c_cast + ' as ctext, ' + 
		'''' + @sT_name + ''' as tab, ' + 
		'''' + @colname + ''' as col ' +
    ' from ' + @sT_name + ' with (nolock) ' +
    ' where (' + @c_cast + ' like ''%<%'' ' +
		'and ' + @c_cast + ' like ''%>%'') ' +
		' or ' + @c_cast + ' like ''%script:%'' ' + 
		' or ' + @c_cast + ' like ''%://%'' ' +
		' or ' + @c_cast + ' like ''%href%'' ' + 
		' or ' + @c_cast + ' like ''%return %'' ' +
		' or ' + @c_cast + ' like ''%mailto:%'' '

  Execute sp_executesql @execSQL;
  Fetch Next From InjectCursor Into @colname, @c_cast, @sT_name
End

Close InjectCursor
Deallocate InjectCursor

Select Distinct * From ##InjWatch
GO 