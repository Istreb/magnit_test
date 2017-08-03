--добавляем job с параметрами как в примере
DBMS_SCHEDULER.CREATE_JOB (
                job_name => '"CLAIM"."COMPLICATED_SCHEDULE_J"',
                job_type => 'PLSQL_BLOCK',
                job_action => 'select 1 from dual;',
                number_of_arguments => 0,
                start_date => NULL,
                repeat_interval => 'FREQ=YEARLY;BYMONTH=JAN,FEB,MAR,APR,MAY,JUN,JUL,AUG,SEP,OCT,NOV,DEC;BYMONTHDAY=3,6,14,18,21,24,28;BYDAY=MON,FRI,SUN;BYHOUR=12;BYMINUTE=0,45',
                end_date => NULL,
                enabled => FALSE,
                auto_drop => FALSE,
                comments => ''
            );
            
--следующий селект выдает следующую дату запуска job'а
select next_run_date from all_scheduler_jobs where job_name='COMPLICATED_SCHEDULE_J';