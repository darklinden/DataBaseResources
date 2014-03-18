--创建自动编译失效过程事务记录表
declare
  tabcnt integer := 0;
begin
  select count(*) into tabcnt from dba_tables where table_name='RECOMPILE_LOG';
  if tabcnt = 0 then
    execute immediate 'create table recompile_log(rdate date,errmsg varchar2(200))';
  end if;
end;
/

--创建编译某个用户下的失效对象的存储过程
create or replace procedure recompile_invalid_objects
as
  str_sql varchar2(200);  --中间用到的sql语句
  p_owner varchar2(20);   --所有者名称，即SCHEMA
  errm varchar2(200);     --中间错误信息
begin
  /*****************************************************/
  /**********************用户名*************************/
  p_owner := 'HIS';   --HIS即为登陆的用户名，按需求修改
  /*****************************************************/
  insert into recompile_log(rdate, errmsg) values(sysdate,'time to recompile invalid objects');

  --编译失效存储过程
  for invalid_procedures in (select object_name from all_objects
    where status = 'INVALID' and object_type = 'PROCEDURE' and owner=upper(p_owner))
  loop
    str_sql := 'alter procedure ' ||invalid_procedures.object_name || ' compile';
    begin
      execute immediate str_sql;
    exception
      When Others Then
      begin
        errm := 'error by obj:'||invalid_procedures.object_name||' '||sqlerrm;
        insert into recompile_log(rdate, errmsg) values(sysdate,errm);
      end;
    end;
  end loop;

  --编译失效函数
  for invalid_functions in (select object_name from all_objects
    where status = 'INVALID' and object_type = 'FUNCTION' and owner=upper(p_owner))
  loop
    str_sql := 'alter function ' ||invalid_functions.object_name || ' compile';
    begin
      execute immediate str_sql;
    exception
      When Others Then
      begin
        errm := 'error by obj:'||invalid_functions.object_name||' '||sqlerrm;
        insert into recompile_log(rdate, errmsg) values(sysdate,errm);
      end;
    end;
  end loop;

  --编译失效包
  for invalid_packages in (select object_name from all_objects
    where status = 'INVALID' and object_type = 'PACKAGE' and owner=upper(p_owner))
  loop
    str_sql := 'alter package ' ||invalid_packages.object_name || ' compile';
    begin
      execute immediate str_sql;
    exception
      When Others Then
      begin
        errm := 'error by obj:'||invalid_packages.object_name||' '||sqlerrm;
        insert into recompile_log(rdate, errmsg) values(sysdate,errm);
      end;
    end;
  end loop;

  --编译失效类型
  for invalid_types in (select object_name from all_objects
    where status = 'INVALID' and object_type = 'TYPE' and owner=upper(p_owner))
  loop
    str_sql := 'alter type ' ||invalid_types.object_name || ' compile';
    begin
      execute immediate str_sql;
    exception
      When Others Then
      begin
        errm := 'error by obj:'||invalid_types.object_name||' '||sqlerrm;
        insert into recompile_log(rdate, errmsg) values(sysdate,errm);
      end;
    end;
  end loop;

  --编译失效索引
  for invalid_indexs in (select object_name from all_objects
    where status = 'INVALID' and object_type = 'INDEX' and owner=upper(p_owner))
  loop
    str_sql := 'alter index ' ||invalid_indexs.object_name || ' rebuild';
    begin
      execute immediate str_sql;
    exception
      When Others Then
      begin
        errm := 'error by obj:'||invalid_indexs.object_name||' '||sqlerrm;
        insert into recompile_log(rdate, errmsg) values(sysdate,errm);
      end;
    end;
  end loop;

  --编译失效触发器
  for invalid_triggers in (select object_name from all_objects
    where status = 'INVALID' and object_type = 'TRIGGER' and owner=upper(p_owner))
  loop
    str_sql := 'alter trigger ' ||invalid_triggers.object_name || ' compile';
    begin
      execute immediate str_sql;
    exception
      When Others Then
      begin
        errm := 'error by obj:'||invalid_triggers.object_name||' '||sqlerrm;
        insert into recompile_log(rdate, errmsg) values(sysdate,errm);
      end;
    end;
  end loop;

end;
/

--创建任务计划，每天早上8点整执行该任务
declare
  jobcnt integer :=0;
  job_recompile number := 0;
  str_sql varchar2(200);
begin
  select count(*) into jobcnt from all_jobs where what = 'recompile_invalid_objects;' and broken = 'N';
  if jobcnt > 0 then
    for jobs in (select job from all_jobs where what = 'recompile_invalid_objects;' and broken = 'N')
    loop
      str_sql := 'begin dbms_job.remove('||jobs.job||'); end;';
      begin
        execute immediate str_sql;
      exception
        When Others Then null;
      end;
    end loop;
  end if;
  --创建任务计划
  dbms_job.submit(job_recompile,'recompile_invalid_objects;',sysdate,'TRUNC(SYSDATE + 1) + 8/24');
  --启动任务计划
  dbms_job.run(job_recompile);
end;
/