--查询数据库所有表名和注释
select table_name,comments from user_tab_comments where table_name not like 'BIN$%'

--查询数据库所有表字段名、注释、是否可为空、数据格式、长度
select a.column_name,b.comments,a.nullable,a.data_type,a.data_length,
       (select au.constraint_type from user_cons_columns cu, user_constraints au
        where au.constraint_type = 'P' and cu.constraint_name = au.constraint_name
              and cu.table_name=a.table_name
              and cu.column_name=a.column_name
       ) as Pkey
from user_tab_columns a,user_col_comments b
where a.table_name=b.table_name
      and a.column_name=b.column_name
order by column_id

--查询所做的操作
select sql_text as "简略SQL语句",sql_fulltext as "SQL字串",parsing_schema_name as "执行者",module as "执行程序",last_active_time as "作用时间"
from v$sqlarea
where parsing_schema_name = 'HIS' and module = 'BrainSrvr.exe' --执行者为HIS，执行程序为BrainSrvr.exe
order by last_active_time desc

--EXCEL公式，替换指定内容拼出oracle创建表的数据格式
=IF(MID(E3,1,7)="varchar","varchar2("&MID(E3,8,3)&")",E3)
--EXCEL公式，可空格式
=IF(H3="Y","Y","N")

--查询数据库所有非临时表
select table_name from USER_TABLES where temporary = 'N'；

--取数据库中所有同义词
select * from all_objects t,all_synonyms s where t.object_type = 'synonym' and t.object_name=s.synonym_name;

--取非系统定义的所有同义词
select * from user_objects t,user_synonyms s where t.object_type = 'synonym' and t.object_name=s.synonym_name;

--用同义词创建表别名
create synonym "与好友接口中医院编码对照" for INTERFACE_YLJGDZ;

--直接查询表别名
select * from 与好友接口中医院编码对照;

--取数据库当前运行中的SQL语句
select * from v$session natural inner join v$sql;

--取数据库运行中和运行过的sql语句
select * from v$sqlarea order by last_active_time desc;



--打印乘法口诀
--方法1
declare
i int;
j int;
lj varchar2(100);
begin
i:=1;
while i<=9 loop
j:=1;lj:='';
while j<=i loop
lj:=lj||'  '||i||'x'||j||'='||(i*j);
j:=j+1;
end loop;
i:=i+1;
dbms_output.put_line((i-1)||lj);
end loop;
end;
--方法2
select    case when 1<=rn then '1*'||rn||'='||(1*rn) else null end,
          case when 2<=rn then '2*'||rn||'='||(2*rn) else null end,
          case when 3<=rn then '3*'||rn||'='||(3*rn) else null end,
          case when 4<=rn then '4*'||rn||'='||(4*rn) else null end,
          case when 5<=rn then '5*'||rn||'='||(5*rn) else null end,
          case when 6<=rn then '6*'||rn||'='||(6*rn) else null end,
          case when 7<=rn then '7*'||rn||'='||(7*rn) else null end,
          case when 8<=rn then '8*'||rn||'='||(8*rn) else null end,
          case when 9<=rn then '9*'||rn||'='||(9*rn) else null end
from
(select rownum rn from dual connect by rownum<=9) tab
order by rn asc

--由树表生成树
select CONNECT_BY_ISLEAF,LEVEL,dwbm,dwmc,(select dwmc from dwxx where dwbm = t.zgbm) as zg from dwxx t
start with dwbm = '41050000000000000000000000' --起始根节点
connect by zgbm = prior dwbm --继承节点=上一行节点
ORDER SIBLINGS BY dwbm

--查询编码，名称，该单位在其分组中的排名
select dwbm,dwmc,(select dwmc from dwxx where dwbm = t.zgbm) as zgmc,
       count(*) over (partition by zgbm order by dwmc )
from dwxx t

--结构化病历树的查询
select CONNECT_BY_ISLEAF,LEVEL,blnrxlh,
       decode(jglx,'Section','# 数据节 #','text','# 数据文本 #',
              (select yssm from emr_blys where ysbh = jglx)) as jglx,
       decode(jglx,'Section',(select lbmc from emr_blnrlb where lbbh = jgz),jgz) as jgz,
       fxlh
from (select '105' as blid,'0' as blnrxlh,'text' as jglx,'root' as jgz,'-1' as fxlh from dual t  --虚根
      union
      select t.* from emr_jghbl t where blid = '105') --单ID下的病历结构树
start with blnrxlh = '0' --起始根节点
connect by fxlh = prior blnrxlh --继承节点 = 上一行节点
ORDER SIBLINGS BY to_number(blnrxlh)

--分析函数 上几行的值积总和
with t_test as
(
select 1 id, 12 a, 19 b, 0 c from dual union all
select 2, 15 , 17 , 0 from dual union all
select 5, 11 , 32 , 0 from dual union all
select 6, 18 , 79 , 0 from dual union all
select 3, 23 , 342, 0 from dual union all
select 4, 134, 545, 0 from dual

)

select id,a,b,c,nvl(sum((a*b)) over( order by id rows between unbounded preceding and 1 preceding),0)
  from t_test


--这个是查看空闲空间的
select tablespace_name,sum(bytes)/1024/1024 ||'M' free_space from user_free_space group by tablespace_name ;

--这个是查看总的数据文件大小
select tablespace_name,sum(bytes)/1024/1024 ||'M' whole_space from dba_data_files group by tablespace_name ;

--查询死锁
SELECT  bs.username "Blocking User", bs.username "DB User",
        ws.username "Waiting User", bs.SID "SID", ws.SID "WSID",
        bs.serial# "Serial#", bs.sql_address "address",
        bs.sql_hash_value "Sql hash", bs.program "Blocking App",
        ws.program "Waiting App", bs.machine "Blocking Machine",
        ws.machine "Waiting Machine", bs.osuser "Blocking OS User",
        ws.osuser "Waiting OS User", bs.serial# "Serial#",
        ws.serial# "WSerial#",
        DECODE (wk.TYPE,
                'MR', 'Media Recovery',
                'RT', 'Redo Thread',
                'UN', 'USER Name',
                'TX', 'Transaction',
                'TM', 'DML',
                'UL', 'PL/SQL USER LOCK',
                'DX', 'Distributed Xaction',
                'CF', 'Control FILE',
                'IS', 'Instance State',
                'FS', 'FILE SET',
                'IR', 'Instance Recovery',
                'ST', 'Disk SPACE Transaction',
                'TS', 'Temp Segment',
                'IV', 'Library Cache Invalidation',
                'LS', 'LOG START OR Switch',
                'RW', 'ROW Wait',
                'SQ', 'Sequence Number',
                'TE', 'Extend TABLE',
                'TT', 'Temp TABLE',
                wk.TYPE
               ) lock_type,
        DECODE (hk.lmode,
                0, 'None',
                1, 'NULL',
                2, 'ROW-S (SS)',
                3, 'ROW-X (SX)',
                4, 'SHARE',
                5, 'S/ROW-X (SSX)',
                6, 'EXCLUSIVE',
                TO_CHAR (hk.lmode)
               ) mode_held,
        DECODE (wk.request,
                0, 'None',
                1, 'NULL',
                2, 'ROW-S (SS)',
                3, 'ROW-X (SX)',
                4, 'SHARE',
                5, 'S/ROW-X (SSX)',
                6, 'EXCLUSIVE',
                TO_CHAR (wk.request)
               ) mode_requested,
        TO_CHAR (hk.id1) lock_id1, TO_CHAR (hk.id2) lock_id2,
        DECODE
           (hk.BLOCK,
            0, 'NOT Blocking',          /**//* Not blocking any other processes */
            1, 'Blocking',              /**//* This lock blocks other processes */
            2, 'Global',           /**//* This lock is global, so we can't tell */
            TO_CHAR (hk.BLOCK)
           ) blocking_others
FROM v$lock hk, v$session bs, v$lock wk, v$session ws
WHERE hk.BLOCK = 1
      AND hk.lmode != 0
      AND hk.lmode != 1
      AND wk.request != 0
      AND wk.TYPE(+) = hk.TYPE
      AND wk.id1(+) = hk.id1
      AND wk.id2(+) = hk.id2
      AND hk.SID = bs.SID(+)
      AND wk.SID = ws.SID(+)
      AND (bs.username IS NOT NULL)
      AND (bs.username <> 'SYSTEM')
      AND (bs.username <> 'SYS')
ORDER BY 1;

--查看死锁语句
select sql_text
from v$sql
where hash_value in
                (select sql_hash_value
                 from v$session
                 where sid in
                          (select session_id from v$locked_object))

--解决死锁
select 'alter system kill session '''||s.sid||','||s.serial#||''';' as code
from v$locked_object l,dba_objects o ,v$session s
where l.object_id = o.object_id and l.session_id=s.sid;

--出现BIN$表名的解决办法
--查询回收站
select t.object_name,t.type ,t.original_name FROM user_recyclebin t;

--清空回收站
PURGE recyclebin;

--查询数据库中存在隐患的字段
select owner, column_name, table_name, data_length
from all_tab_columns
where column_name in
  (select column_name from all_tab_columns t group by column_name having count(distinct data_type)>1
   --字段名相同而类型不符
   union
   select column_name from all_tab_columns t group by column_name,data_type having count(distinct data_length)>1)
   --字段名相同类型相同而长度不符
order by column_name,table_name;

--XMLTYPE
--创建xml表
create table xmltest( id number , xml sys.xmltype );
--插入数据
--直接插入xml
insert into xmltest (id,xml)
values ( 1 , sys.xmlType.createXML( '<name><a id="1" value="some values">abc</a></name>' ) );

select i.xml.extract('//name/a[@id=1]/text()').getStringVal() as ennames, id from xmltest i

update xmltest set xml=updateXML(xml,'//name/a[@id=1]/@value','some new value')

select id, t.xml.getclobval() xml from xmltest t