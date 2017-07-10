/* create database casper */
CREATE DATABASE IF NOT EXISTS casper;

/* display current database */
SHOW DATABASES;

/* select database casper */
USE casper;

/* create table dat */
CREATE TABLE IF NOT EXISTS dat(
       dateordered DATE,
       datereturned DATE,
       orderstatus VARCHAR(20),
       orders INT);

/* discribe table dat */
DESCRIBE dat;

/* import XLS_takehome_NA.csv to table dat */
LOAD DATA LOCAL INFILE 'XLS_takehome_NA.csv'
     INTO TABLE dat
     FIELDS TERMINATED BY ','
     LINES TERMINATED BY '\n'
     IGNORE 1 LINES
     (@dateordered,
      @datereturned,
      orderstatus,
      orders)
     SET
     dateordered=STR_TO_DATE(@dateordered, '%m/%d/%Y'),
     datereturned=STR_TO_DATE(@datereturned, '%m/%d/%Y');

/* add column day_before_return*/
ALTER table dat
ADD day_before_return INT;

UPDATE dat
SET day_before_return = TIMESTAMPDIFF(DAY, dat.dateordered, dat.datereturned);

/* display all coloumns */
SELECT * FROM dat;
