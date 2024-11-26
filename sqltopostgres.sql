declare @databaseName varchar(100)
declare @sourceschmea varchar(100) = 'localsql.dbo.',@destinationschema varchar(100) = 'postgres.public.'
set @databaseName = 'lead'

--Table script
select isnull(try_cast('create table ' + replace((
			lower( concat(@destinationschema,lower(Results.table_name), ' as ' , 'select '))
			),'','') + char(13)  + STUFF((
				select ', ' + char(13) + lower( char(9) + lower (
							case replace(column_name,' ','_')
								when 'order'
									then '"order"'
								when 'default'
									then '"default"'
								when 'offset'
									then '"offset"'
								else replace(column_name,' ','_')
								end
							)  + ' as ' + [dbo].[udf_SpacesForCases]((column_name)))
				from INFORMATION_SCHEMA.COLUMNS
				where (
						table_name = Results.table_name
						and TABLE_SCHEMA = Results.TABLE_SCHEMA
						)
				for xml PATH('')
					,TYPE
				).value('(./text())[1]', 'VARCHAR(MAX)'), 1, 2, '') + char(13) + ' from ' + @sourceschmea + Results.table_name + char(13) + char(13) as xml),'') as abc, Results.TABLE_SCHEMA + '.' + Results.table_name  tablename
from INFORMATION_SCHEMA.COLUMNS Results
JOIN INFORMATION_SCHEMA.TABLES t ON Results.TABLE_NAME = t.TABLE_NAME
AND t.TABLE_TYPE = 'BASE TABLE'
where OBJECT_ID(Results.TABLE_SCHEMA + '.' + Results.table_name) not in (
		select object_id
		from sys.views
		)
	and Results.TABLE_SCHEMA + '.' + Results.table_name in (
		select tablename
		from include_table_list
		)
	or (
		select count(1)
		from include_table_list
		) = 0
group by Results.TABLE_SCHEMA
	,Results.table_name
