



.bail on
-- .echo on
.headers on
.mode column
.nullvalue 'x'
.width 100
.timer on
-- .help
-- .tables
-- .schema

-- drop table if exists customers;
-- CREATE VIRTUAL TABLE customers USING fts5(
--     name,
--     addr,
--     uuid UNINDEXED,
--     -- tokenize = 'unicode61 remove_diacritics 2'
--     tokenize = 'unicode61'
--     );

-- drop table if exists customers;
-- CREATE VIRTUAL TABLE customers USING fts5(a, b,
--     tokenize = "unicode61 categories 'L* N* Co Mn'"
-- );
-- xxx;





/*
drop table if exists foo;
create table foo (
  input   text not null,
  output  text not null );

insert into foo values
  ( 1, 2 ),
  ( 3, 4 ),
  ( 5, 6 ),
  ( 7, 8 ),
  ( 9, 10 ),
  ( 11, 12 ),
  ( 13, 14 ),
  -- ( 13, null ),
  ( 15, 16 );

select * from foo;
*/

-- .show
-- .exit
drop table if exists cjk_variants;
drop table if exists cjk_ranks;
drop table if exists cjk_sims;
drop table if exists cjk_strokeorders;
drop table if exists cjk_usagecode;
drop table if exists html_entities_1;
drop table if exists html_entities_2;
drop table if exists julia_latex;
drop table if exists unicode_entities;
drop table if exists unames;
drop table if exists texnames;
.mode csv
-- .import 'db/variants.csv'                     cjk_variants
-- .import 'db/ranks.csv'                        cjk_ranks
-- .import 'db/sims.csv'                         cjk_sims
-- .import 'db/strokeorders.csv'                 cjk_strokeorders
-- .import 'db/usagecode.csv'                    cjk_usagecode
-- .import 'db/html-entities-1.csv'              html_entities_1
-- .import 'db/html-entities-2.csv'              html_entities_2
-- .import 'db/julia-latex.csv'                  julia_latex
-- .import 'db/unicode-names-and-entities.csv'   unicode_entities

.print '--=(1)=--'
.import 'db/unames.csv'         unames
.print '--=(2)=--'
.import 'db/texnames.csv'       texnames

.mode column
-- select * from cjk_variants      limit 10;  select count(*) from cjk_variants;
-- select * from cjk_ranks         limit 10;  select count(*) from cjk_ranks;
-- select * from cjk_sims          limit 10;  select count(*) from cjk_sims;
-- select * from cjk_strokeorders  limit 10;  select count(*) from cjk_strokeorders;
-- select * from cjk_usagecode     limit 10;  select count(*) from cjk_usagecode;
-- select * from html_entities_1   limit 10;  select count(*) from html_entities_1;
-- select * from html_entities_2   limit 10;  select count(*) from html_entities_2;
-- select * from julia_latex       limit 100; select count(*) from julia_latex;
-- select * from unames    limit 100; select count(*) from unames;
-- select * from texnames  limit 100; select count(*) from texnames;

.print '--=(3)=--'
drop table if exists data;
create virtual table data using fts5(
  input,
  output,
  cid_hex,
  -- tokenize = "unicode61"
  tokenize = "unicode61, remove_diacritics = 2"
  -- tokenize=unicode61 "remove_diacritics=2" );
  -- tokenize = 'unicode61'
  );
  -- tokenize = 'porter ascii' );

.print '--=(4)=--'
insert into data ( input, output, cid_hex ) select
    texname,
    glyph,
    cid_hex
  from texnames;

.print '--=(5)=--'
insert into data ( input, output, cid_hex ) select
    uname,
    glyph,
    cid_hex
  from unames;

insert into data ( input, output, cid_hex ) values
  ( '日本',                                           'japanese', 'xxx' ),
  ( '日本語',                                        'japanese', 'xxx' ),
  ( 'これは日本語で書かれています',                   'japanese', 'xxx' ),
  ( ' これは　日本語の文章を 全文検索するテストです',   'japanese', 'xxx' );

-- optimize index:
.print '--=(6)=--'
-- insert into data ( data ) values ( 'optimize' );
insert into data ( data ) values ( 'rebuild' );

select count(*) from data;


-- select * from data where input match 'alpha';
-- select distinct output from data where input match 'arrow downwards';
-- select * from data where output match 'a';
-- select * from data where input match 'arrow%';
-- select matchinfo( data, 'y' ), * from data where input match 'greek letter alpha';
-- select snippet( data ), * from data where input match 'greek letter alpha';
-- select snippet( data ), * from data where input match 'greek -letter';
-- select snippet( data ), * from data where input match 'down*';


-- drop view if exists unicode_entities_01;
-- create view unicode_entities_01 as select
--     ID                      as ID,
--     "UNICODE DESCRIPTION"   as uname,
--     Entity                  as entity,
--     -- mode                    as mode,
--     -- type                    as type,
--     -- replace( latex, char( 92 ), '' )                   as latex
--     replace( latex, char( 0x5c ), '' )                   as latex
--     -- category                as category,
--     -- "op dict"               as "op dict",
--   from unicode_entities
--   -- order by "UNICODE DESCRIPTION"
--   order by latex desc
--   ;

-- select * from unicode_entities_01  limit 100; select count(*) from unicode_entities_01;

