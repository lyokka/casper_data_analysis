/*select database*/
USE casper

/*****************************************
create table `tab_returns_on_returned_day`

This table contains 3 columns:
     1. dates
     2. complete orders on that day
     3. returned orders on that day(returned day)
******************************************/
CREATE TABLE IF NOT EXISTS tab_returns_on_returned_day 
SELECT tab_comp.dateordered AS dates,
       tab_comp.orders AS complete_orders,
       tab_ret.orders AS returns_on_returned_day FROM
       (
        SELECT dateordered, orders
        FROM dat
        WHERE orderstatus = 'complete'
       ) AS tab_comp
LEFT OUTER JOIN
       (
        SELECT DATE(datereturned) AS datereturned, SUM(orders) AS orders
        FROM dat
        WHERE orderstatus = 'returned'
        GROUP BY DATE(datereturned)
       ) AS tab_ret
ON tab_comp.dateordered = tab_ret.datereturned
UNION
SELECT tab_ret.datereturned AS dates,
       tab_comp.orders AS complete_orders,
       tab_ret.orders AS returns_on_returned_day FROM
       (
        SELECT dateordered, orders
        FROM dat
        WHERE orderstatus = 'complete'
       ) AS tab_comp
RIGHT OUTER JOIN
       (
        SELECT DATE(datereturned) AS datereturned, SUM(orders) AS orders
        FROM dat
        WHERE orderstatus = 'returned'
        GROUP BY DATE(datereturned)
       ) AS tab_ret
ON tab_comp.dateordered = tab_ret.datereturned;

/*****************************************
create table `tab_returns_on_ordered_day`

This table contains 2 columns:
     1. dates
     2. returned orders on ordered day
******************************************/
CREATE TABLE IF NOT EXISTS tab_returns_on_ordered_day
SELECT DATE(dateordered) AS dates, SUM(orders) AS returns_on_ordered_day
FROM dat
WHERE orderstatus = 'returned'
GROUP BY DATE(dateordered)
ORDER BY dates;

/*****************************************
create table `casper_order`

This table contains 4 columns:
     1. dates
     2. complete orders on orders day
     3. returned orders on returned day
     4. returned orders on ordered day
******************************************/
CREATE TABLE IF NOT EXISTS casper_order
SELECT tab_returns_on_returned_day.dates as dates,
       tab_returns_on_returned_day.complete_orders as complete_orders,
       tab_returns_on_returned_day.returns_on_returned_day as returns_on_returned_day,
       tab_returns_on_ordered_day.returns_on_ordered_day as returns_on_ordered_day
       FROM tab_returns_on_returned_day
LEFT OUTER JOIN
       tab_returns_on_ordered_day
ON tab_returns_on_returned_day.dates = tab_returns_on_ordered_day.dates
ORDER BY dates;
