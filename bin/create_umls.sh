#!/bin/sh

if [ -n "$1" ]
then
  version="$1"
else
  version="2023"
fi

echo "Version: ${version}"

tmpdir="./tmp/terminology/${version}"

umls_db_location=${tmpdir}/umls.db

echo 'Dropping existing mrconso table'
sqlite3 $umls_db_location "drop table if exists mrconso"

echo 'Creating mrconso table'
sqlite3 $umls_db_location "create table mrconso (
        CUI	char(8) NOT NULL,
        LAT	char(3) NOT NULL,
        TS	char(1) NOT NULL,
        LUI	char(8) NOT NULL,
        STT	varchar(3) NOT NULL,
        SUI	char(8) NOT NULL,
        ISPREF	char(1) NOT NULL,
        AUI	varchar(9) NOT NULL,
        SAUI	varchar(50),
        SCUI	varchar(50),
        SDUI	varchar(50),
        SAB	varchar(20) NOT NULL,
        TTY	varchar(20) NOT NULL,
        CODE	varchar(50) NOT NULL,
        STR	text NOT NULL,
        SRL	int NOT NULL,
        SUPPRESS	char(1) NOT NULL,
        CVF	int
      );"

# Remove the last pipe from each line
if [ ! -e ${tmpdir}/MRCONSO.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed -e 's/|$//' -e "s/\"/'/g" ${tmpdir}/umls_subset/MRCONSO.RRF > ${tmpdir}/MRCONSO.pipe
fi

echo 'Populating mrconso table'
sqlite3 $umls_db_location ".import ${tmpdir}/MRCONSO.pipe mrconso"

echo 'Dropping existing mrrel table'
sqlite3 $umls_db_location "drop table if exists mrrel;"

echo 'Creating mrrel table'
sqlite3 $umls_db_location "create table mrrel (
        CUI1	char(8) NOT NULL,
        AUI1	varchar(9),
        STYPE1	varchar(50) NOT NULL,
        REL	varchar(4) NOT NULL,
        CUI2	char(8) NOT NULL,
        AUI2	varchar(9),
        STYPE2	varchar(50) NOT NULL,
        RELA	varchar(100),
        RUI	varchar(10) NOT NULL,
        SRUI	varchar(50),
        SAB	varchar(20) NOT NULL,
        SL	varchar(20) NOT NULL,
        RG	varchar(10),
        DIR	varchar(1),
        SUPPRESS	char(1) NOT NULL,
        CVF	int
      );"

# Remove the last pipe from each line
if [ ! -e ${tmpdir}/MRREL.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed 's/|$//' ${tmpdir}/umls_subset/MRREL.RRF > ${tmpdir}/MRREL.pipe
fi

echo 'Populating mrrel table'
sqlite3 $umls_db_location ".import ${tmpdir}/MRREL.pipe mrrel"

echo 'Dropping existing mrsat table'
sqlite3 $umls_db_location "drop table if exists mrsat;"

echo 'Creating mrsat table'
sqlite3 $umls_db_location "create table mrsat (
        CUI 	char(8) NOT NULL,
        LUI       char(8),
        SUI       char(8),
        METAUI    varchar(20),
        STYPE	varchar(50) NOT NULL,
        CODE      varchar(50),
        ATUI      varchar(10) NOT NULL,
        SATUI     varchar(10),
        ATN       varchar(50),
        SAB	      varchar(20) NOT NULL,
        ATV       varchar(1000) NOT NULL,
        SUPPRESS	char(1),
        CVF	int
      );"

# Remove the last pipe from each line, and quote all the fields/escape double quotes
# Because MRSAT has stray unescaped quotes in one of the fields
if [ ! -e ${tmpdir}/MRSAT.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed 's/|$//' ${tmpdir}/umls_subset/MRSAT.RRF | sed $'s/"/""/g;s/[^|]*/"&"/g' > ${tmpdir}/MRSAT.pipe
fi

echo 'Populating mrsat table'
sqlite3 $umls_db_location ".import ${tmpdir}/MRSAT.pipe mrsat"

echo 'Dropping existing mrsab table'
sqlite3 $umls_db_location "drop table if exists mrsab"

echo 'Creating mrsab table'
sqlite3 $umls_db_location "create table mrsab (
        VCUI char(8),
        RCUI char(8),
        VSAB varchar(40),
        RSAB varchar(40),
        SON varchar(3000),
        SF varchar(40),
        SVER varchar(20),
        VSTART char(8),
        VEND char(8),
        IMETA varchar(10),
        RMETA varchar(10),
        SLC varchar(1000),
        SCC varchar(1000),
        SRL integer,
        TFR integer,
        CFR integer,
        CXTY varchar(50),
        TTYL varchar(400),
        ATNL varchar(4000),
        LAT char(3),
        CENC varchar(20),
        CURVER char(1),
        SABIN char(1),
        SSN varchar(3000),
        SCIT varchar(4000)
      );"

# Remove the last pipe from each line
if [ ! -e ${tmpdir}/MRSAB.pipe ]
then
 echo 'Removing last pipe from RRF'
 sed -e 's/|$//' -e "s/\"/'/g" ${tmpdir}/umls_subset/MRSAB.RRF > ${tmpdir}/MRSAB.pipe
fi

echo 'Populating mrsab table'
sqlite3 $umls_db_location ".import ${tmpdir}/MRSAB.pipe mrsab"

### MRSAT indices ###

echo 'Indexing mrsat(SAB,ATN,ATV)'
sqlite3 $umls_db_location "create index idx_sab_atn_atv on mrsat(SAB,ATN,ATV);"

### MRCONSO indices ###

echo 'Indexing mrconso(AUI)'
sqlite3 $umls_db_location "CREATE INDEX idx_aui ON mrconso(AUI);"

echo 'Indexing mrconso(SAB,TTY)'
sqlite3 $umls_db_location "create index idx_sab_tty on mrconso(SAB,TTY);"

### MRREL indices ###

echo 'Indexing mrrel(REL,SAB)'
sqlite3 $umls_db_location "create index idx_rel_sab on mrrel(REL,SAB);"

echo 'Analyzing Database'
sqlite3 $umls_db_location "ANALYZE;"
