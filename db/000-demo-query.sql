
.bail on
-- .echo on
.headers on
.mode column
.nullvalue 'x'
.width 100
-- .timer on


select * from data where input match 'omega' order by rank limit 10;
.print '--------------------'
select * from data where input match 'Omega' order by rank limit 10;
.print '--------------------'
select * from data where input match '日本語' order by rank limit 10;
.print '--------------------'
select * from data where input match '日本' order by rank limit 10;
.print '--------------------'
-- select * from data where input match 'alpha';
-- select distinct output from data where input match 'arrow downwards';
-- select * from data where output match 'a';
-- select * from data where input match 'arrow%';
-- select matchinfo( data, 'y' ), * from data where input match 'greek letter alpha';
-- select snippet( data ), * from data where input match 'greek letter alpha';
-- select snippet( data ), * from data where input match 'greek -letter';
-- select snippet( data ), * from data where input match 'down*';


