drop user HIS cascade; --级联删除用户 HIS
DROP TABLESPACE tsp_his INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;--删除表空间
DROP TABLESPACE HIS_TMP INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;--删除表空间

--del C:\oracle\product\10.2.0\oradata\His\his_tmp01.dbf;
--del C:\oracle\product\10.2.0\oradata\His\tsp_his01.dbf;

--创建临时表空间
create temporary tablespace HIS_TMP
tempfile 'C:\oracle\product\10.2.0\oradata\His\his_tmp01.dbf'
size 32m
autoextend on
next 32m maxsize 2048m
extent management local;

--创建数据表空间
create tablespace tsp_his
logging
datafile 'C:\oracle\product\10.2.0\oradata\His\tsp_his01.dbf'
size 15000m
autoextend on
next 100m maxsize 20000m
extent management local;

--创建用户并指定表空间
create user HIS identified by his2926666
default tablespace tsp_his
temporary tablespace HIS_TMP;
--给用户授予权限
grant DBA to HIS;

alter database datafile 'e:\test_db01.dbf' autoextend on next 100m maxsize 20000m;


