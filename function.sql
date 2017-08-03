--------------------------------------------------------
--  File created - четверг-августа-03-2017   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Function A_TEST
--------------------------------------------------------

  CREATE OR REPLACE FUNCTION "CLAIM"."A_TEST" (
        v_date      IN DATE,
        v_string    IN VARCHAR2
    ) 
RETURN DATE AS 
    comma NUMBER;
    commas NUMBER;
    semicolon NUMBER;
    semicolons NUMBER;
    
    i_date DATE;
    
    type parArray IS VARRAY(5) OF VARCHAR2(10); 
    par parArray;
    
    type dateParValuesArray IS VARRAY(31) OF NUMBER; 
    type dateParArray IS VARRAY(5) OF dateParValuesArray; 
    v_row dateParValuesArray;
    rValues dateParArray;
    
    dayweek CHAR(1);
    
    YY NUMBER;
    MM NUMBER;
    DD NUMBER;
    hh24 NUMBER;
    MI NUMBER;
BEGIN
    execute immediate 'alter session set NLS_TERRITORY = AMERICA'; --дни недели в американском стиле: 1-sun, 2-mon...
    par := parArray('MI', 'HH24', 'D', 'DD', 'MM'); 
    v_row := dateParValuesArray();
    rValues := dateParArray();
    
    select length(v_string) - length(replace(v_string,';',null)) 
    into semicolons
    from dual; --количество запятых
    semicolon := 0;
  
    --1. Парсим строку
    FOR FOO IN (
        SELECT REGEXP_SUBSTR (v_string, '[^;]+',1,LEVEL) str
        FROM DUAL
        CONNECT BY REGEXP_SUBSTR (v_string, '[^;]+', 1, LEVEL) IS NOT NULL
    )
    LOOP
        IF semicolon <= semicolons then
            select length(FOO.str) - length(replace(FOO.str,',',null)) 
            into commas
            from dual; --количество ;
            comma := 0;
            
            FOR BAR IN (
                SELECT REGEXP_SUBSTR (FOO.str, '[^,]+',1,LEVEL) str
                FROM DUAL
                CONNECT BY REGEXP_SUBSTR (FOO.str, '[^,]+', 1, LEVEL) IS NOT NULL
            )
            LOOP
                IF comma <= commas then
                    v_row.EXTEND;
                    v_row(v_row.count) := to_number(BAR.str);
                end if;
                comma := comma +1;
            end loop;
            rValues.EXTEND;
            rValues(rValues.count) := v_row;
            v_row.delete;
        end if;
        semicolon := semicolon +1;
    end loop;
    select v_date into i_date from dual; --добавляем минутку, чтобы не выдало то же время
    YY := to_char(i_date,'YY');
    
    --2. ищем следующую дату 
    LOOP
        --2.1. определяем месяц
        FOR i in 1..rValues(5).count 
        LOOP
            if to_number(to_char(i_date, par(5))) < rValues(5)(i) then
                MM := rValues(5)(i);
                select to_date('01.' || MM || '.' || YY, 'dd.mm.yy') into i_date from dual;
                exit;
            elsif to_number(to_char(i_date, par(5))) = rValues(5)(i) then
                MM := rValues(5)(i);
                exit;
            end if;
        end loop;
        
        if MM is null then 
            select to_date('01.01.' ||(YY+1) || ' ' || to_char(i_date,'hh24') || ':' || to_char(i_date,'MI') , 'dd.mm.yy hh24:mi') into i_date from dual;
            YY := YY+1;
            continue;
        end if;
        
        --2.2. определяем день
        FOR i in 1..rValues(4).count 
        LOOP
            if to_number(to_char(i_date, par(4))) <= rValues(4)(i) then
                DD := rValues(4)(i);
                dayweek := 'N';
                for n in 1..rValues(3).count -- проверяем день недели
                LOOP
                    if rValues(3)(n) = to_number(to_char(to_date( DD || '.' || MM || '.' || YY, 'dd.mm.yy'), 'D')) then
                        if to_number(to_char(i_date, par(4))) = rValues(4)(i) then
                            select to_date( DD || '.' || MM || '.' || YY || ' ' || to_char(i_date,'hh24') || ':' || to_char(i_date,'MI'), 'dd.mm.yy hh24:mi') into i_date from dual;
                        else
                            select to_date( DD || '.' || MM || '.' || YY, 'dd.mm.yy') into i_date from dual;
                        end if;
                        dayweek := 'Y';
                        exit;
                    end if;
                end loop;
                
                if dayweek <> 'Y' then
                    select i_date+(to_date( DD || '.' || MM || '.' || YY, 'dd.mm.yy') - trunc(i_date)) into i_date from dual;
                    continue;
                else
                    exit;
                end if;
            end if;
        end loop;

        --2.3. определяем час
        hh24 := null;
        FOR i in 1..rValues(2).count 
        LOOP
            if to_number(to_char(i_date, par(2))) <= rValues(2)(i) then
                hh24 := rValues(2)(i);
                select to_date( DD || '.' || MM || '.' || YY || ' ' || hh24 || ':' || to_char(i_date,'MI'), 'dd.mm.yy hh24:mi') into i_date from dual;
                exit;
            end if;
        end loop;

        if hh24 is null then
            select trunc(i_date,'hh24')+1/24 into i_date from dual;
            continue;
        end if;
    
        --2.4. определяем минуту
        MI := null;
        FOR i in 1..rValues(1).count 
        LOOP
            if to_number(to_char(i_date, par(1))) <= rValues(1)(i) then
                MI := rValues(1)(i);
                select to_date( DD || '.' || MM || '.' || YY || ' ' || hh24 || ':' || MI, 'dd.mm.yy hh24:mi') into i_date from dual;
                exit;
            end if;
        end loop;
        
        if MI is null then
            select i_date+1/24/60 into i_date from dual;
            continue;
        end if;
        
        --если получили ту же дату, сдвигаем на минутку и запускаем заново
        if i_date = v_date then
            select i_date+1/24/60 into i_date from dual;
            continue;
        end if;
        
        exit;
    end loop;
    
    return i_date;
END A_TEST;

/
