 Set TRANSACTION ISOLATION LEVEL read uncommitted; 

-- Select * from sys.all_objects 
-- Select * from sys.all_columns
-- Select * From sys.index_columns
-- Select * From sys.index_resumable_operations


Select type, type_desc, Count(type) as Counter
From sys.all_objects
Group By  type_desc, type
Order By Counter Desc



select  idx.index_id, idx.name as index_name, idx.type_desc as index_type_desc, 
	(idx.is_unique | idx.is_primary_key | is_unique_constraint) as index_unique, idx.fill_factor, 
	sao.name as table_name, COL_NAME(sic.object_id, sic.column_id) AS column_name, 
	sao.type_desc, idx.object_id
From sys.indexes idx
Inner join sys.all_objects sao 
	on sao.object_id = idx.object_id
Inner join sys.index_columns sic 
	on idx.object_id = sic.object_id and idx.index_id = sic.index_id
Where idx.is_disabled = 0 
	and idx.is_hypothetical = 0
Order by sao.name, idx.name, column_name

-- Select * From sys.index_columns sic
-- Inner join sys.columns scol
-- on  sic.column_id = scol.object_id
-- order by sic.column_id

