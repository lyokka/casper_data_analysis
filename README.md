
# Ye Lin(yl3449@nyu.edu)

## Outline
   - using MySQL process data
   - analyze data(Python MySQL connector)
   - using Python for Data Visualization

## Interests:
   - return rate on each months
   - customers' behavior

## MySQL process data

  1. Setup MySQL base on remote server
  2. Create database `casper` on remote server
  3. Create table `dat` and `casper_order` on remote server

- ### Create database *casper*

------------------------------------------------

```SQL
/* create database casper */
CREATE DATABASE IF NOT EXISTS casper;
```

- ### Create table *dat*

    - Table *dat* contains 5 fields
        - dateordered:  the date that ordered product
        - datereturned: the date that returned product
        - orderstatus:  status of order, either 'complete' or 'returned'
        - orders:            the orders completed on that day
        - day_before_return: days before the product is returned, NULL means the order is not returned

|dateordered|datereturned|orderstatus|orders|day_before_return|
|-----------|------------|-----------|------|-----------------|
|DATE       |DATE        |VARCHAR    |INT   |INT              |
-------------------------------------------------------------------------------
SQL CODE:

```SQL
/* create table dat */
CREATE TABLE IF NOT EXISTS
    dat(dateordered DATE, datereturned DATE, orderstatus VARCHAR(20), orders INT);

/* import XLS_takehome_NA.csv to table dat */
LOAD DATA LOCAL INFILE 'XLS_takehome_NA.csv'
     INTO TABLE dat
     FIELDS TERMINATED BY ','
     LINES TERMINATED BY '\n'
     IGNORE 1 LINES
     (@dateordered, @datereturned, orderstatus, orders)
     SET
     dateordered=STR_TO_DATE(@dateordered, '%m/%d/%Y'),
     datereturned=STR_TO_DATE(@datereturned, '%m/%d/%Y');

/* add column day_before_return*/
ALTER table dat
ADD day_before_return INT;

UPDATE dat
SET day_before_return = TIMESTAMPDIFF(DAY, dat.dateordered, dat.datereturned);
```

- ### Create table *casper_order*

    - Table *casper_order* contains 4 fields
        - dates:  the date
        - complete_orders: number of orders completed on that day
        - returns_on_returned_day: number of orders returned on that day
        - returns_on_ordered_day: number of orders returned on that days' order

|dates|complete_orders|returns_on_returned_day|returns_on_ordered_day|
|-----|---------------|-----------------------|----------------------|
|DATE |INT            |INT                    |INT                   |


To create this table, I created two table first, one is related to returns on returned day, the other is related to returns on ordered day, then combined them on dates.

-------------------------------------------------------------------------------
SQL CODE:



```SQL

/*select database*/
USE casper

/*create table `tab_returns_on_returned_day`

This table contains 3 columns:
     1. dates
     2. complete orders on that day
     3. returned orders on that day(returned day)*/

CREATE TABLE IF NOT EXISTS tab_returns_on_returned_day
SELECT tab_comp.dateordered AS dates,
       tab_comp.orders AS complete_orders,
       tab_ret.orders AS returns_on_returned_day FROM
       (SELECT dateordered, orders FROM dat WHERE orderstatus = 'complete') AS tab_comp
LEFT OUTER JOIN
       (SELECT DATE(datereturned) AS datereturned, SUM(orders) AS orders
        FROM dat WHERE orderstatus = 'returned' GROUP BY DATE(datereturned)) AS tab_ret
ON tab_comp.dateordered = tab_ret.datereturned
UNION
SELECT tab_ret.datereturned AS dates,
       tab_comp.orders AS complete_orders,
       tab_ret.orders AS returns_on_returned_day FROM
       (SELECT dateordered, orders FROM dat WHERE orderstatus = 'complete') AS tab_comp
RIGHT OUTER JOIN
       (SELECT DATE(datereturned) AS datereturned, SUM(orders) AS orders
        FROM dat WHERE orderstatus = 'returned' GROUP BY DATE(datereturned)) AS tab_ret
ON tab_comp.dateordered = tab_ret.datereturned;

/*create table `tab_returns_on_ordered_day`

This table contains 2 columns:
     1. dates
     2. returned orders on ordered day*/
CREATE TABLE IF NOT EXISTS tab_returns_on_ordered_day
SELECT DATE(dateordered) AS dates, SUM(orders) AS returns_on_ordered_day
FROM dat WHERE orderstatus = 'returned' GROUP BY DATE(dateordered)
ORDER BY dates;

/*create table `casper_order`

This table contains 4 columns:
     1. dates
     2. complete orders on orders day
     3. returned orders on returned day
     4. returned orders on ordered day*/
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
```

## Analyze Data

In this report I mainly focusing on 3 points, the first point is return rate on efficiency, the second point is return rate on time, the third point is analysis of customers' returning habbits.

### Return Rate On-Efficiency

**Returns of Orders from that Month: the measure counts the number of orders complete in that month but finally cause returns**

$\text{Return Rate}_{on-efficiency} = \frac{\text{Returns of Orders from that Month}}{ \text{Complete Orders in that Month} } $

**This return rate reflects the efficiency of the order, since it means how many orders made this month will cause returns**

![on-efficiency](/DataAnalysisonCasperData_files/return_eff.png)

In the image above, we could see the return rate(on-efficiency) is decreasing which matches our expectation, but we need to care about the cost of returns will be different in different months. For example, if the transportation cost is high in November and December because of Thanksgiving and Christmas, this return rate measure will not reflect the on time condition on business.

### Return Rate On-Time

**Returns of Orders in that Month: the measure counts the number of orders returned in that month**

$\text{Return Rate}_{on-time} = \frac{\text{Returns of Orders in that Month}}{ \text{Complete Orders in that Month} } $

**This return rate reflects real time condition on returned orders**

![on-efficiency](/DataAnalysisonCasperData_files/return_ontime.png)


In the image above, we could see the return rate(on-time) is relatively flat, in this case we could tell the portion of returned orders is roughly steady in really time. However, if on-time return rate is steady, which will be harmful when the cost of returns increases. In order to analyze whether the company is making progress, we need to analyze users' activity.

### Analysis of Customers' Returning Habbits

I extracted feature ``day_before_return``, which measures how long will customers return their orders. If a customer decide to return the staff, the longer he holds that staff, the worse for business. Therefore, we could study the distribution of feature ``day_before_return``.   

The simplest way to study the distibution is to plot the histogram and box plot of this feature.
![](/DataAnalysisonCasperData_files/distribution.png)
This distribution is highly positive skewed with two peaks. Highly positive skew makes sense, since usually people will return the order after few days they buy it if they don't like it. The peak around 80 days tells us some customers will returns their orders around 2 months after complete orders.

To further analyze the bussiness, I also plot this figure
![](/DataAnalysisonCasperData_files/user.png)
The bar plot is the total amount of orders, we could see the orders are increasing. The red portion of the bar plot is the number of returns. The pie chart above each bar is corresponding day_before_return distribution in pie chart form. We could see the the portion of returning orders in 1-25days doesn't change basicsly, but other portions are decreasing, for example in the pie chart of November, customers maily return orders in 60 days. This is a good sign for business.

### Python Script for Querying MySQL Database and Visualization


```python
# load librarys
import pandas as pd
import numpy as np
import datetime
import mysql.connector
import seaborn as sns
import matplotlib.pyplot as plt

cnx = mysql.connector.connect(user='****', password='*****',
                              host='****',database='casper')
cursor = cnx.cursor()
```


```python
# query table casper_order grouped by month
query = ("SELECT MONTH(dates),"
         "SUM(complete_orders),"
         "SUM(returns_on_returned_day),"
         "SUM(returns_on_ordered_day) "
         "FROM casper_order GROUP BY MONTH(dates)")

cursor.execute(query)
casper_order_month = pd.DataFrame(cursor.fetchall(),
                                  columns=["month", "complete_order_month",
                                           "returns_r_month", "returns_o_month"])
```


```python
rate_eff = casper_order_month.drop([0]) #drop January
rate_eff['net_complete'] = rate_eff.complete_order_month - rate_eff.returns_o_month
rate_eff['net_complete'] = rate_eff.net_complete.apply(float)
rate_eff['returns_rate'] = rate_eff.returns_o_month / rate_eff.complete_order_month
rate_eff.returns_rate = rate_eff.returns_rate.apply(float).round(2)

# plot return rate on efficiency
N, width = 5, 0.35       # the width of the bars: can also be len(x) sequence
ind = np.arange(N)
p = plt.bar(ind, rate_eff.returns_rate*100,
            width, alpha=0.6, edgecolor='k')
plt.ylabel('return rate on efficiency')
plt.title('orders')
plt.xticks(ind, ('Aug', 'Sep', 'Oct', 'Nov', 'Dec'))
for i in ind:
    plt.text(i-0.15,
             rate_eff.returns_rate[i+1]*100+0.05,
             str(rate_eff.returns_rate[i+1]*100)+"%")
plt.show()
```


![png](/DataAnalysisonCasperData_files/output_17_0.png)



```python
rate_ontime = casper_order_month.drop([0,1]) #drop January, Aug
rate_ontime['net_complete'] = rate_ontime.complete_order_month - rate_eff.returns_r_month
rate_ontime['net_complete'] = rate_ontime.net_complete.apply(float)
rate_ontime['returns_rate'] = rate_ontime.returns_r_month / rate_eff.complete_order_month
rate_ontime.returns_rate = rate_ontime.returns_rate.apply(float).round(2)

# plot return rate on efficiency
N = 4
ind = np.arange(N)
p = plt.bar(ind, rate_ontime.returns_rate*100,
            width,alpha=0.6, edgecolor='k')
plt.ylabel('return rate on time')
plt.title('orders')
plt.xticks(ind, ('Sep', 'Oct', 'Nov', 'Dec'))
for i in ind:
    plt.text(i-0.1,
             rate_ontime.returns_rate[i+2]*100+0.05,
             str(rate_ontime.returns_rate[i+2]*100)+"%")

plt.show()
```


![png](/DataAnalysisonCasperData_files/output_18_0.png)



```python
query = ("SELECT MONTH(dateordered), day_before_return "
         "FROM dat")

cursor.execute(query)
return_day = pd.DataFrame(cursor.fetchall(),
                          columns=["month","day_before_return"]).fillna(0)
```


```python
hist_data = np.array(return_day.day_before_return[return_day.day_before_return!=0])
# the histogram of the data
plt.figure(figsize=(10,10))
plt.hist(hist_data, 10,
         normed=1, linewidth=1.5,
         alpha=0.6, edgecolor='k')

plt.xlabel('day before returned')
plt.ylabel('frequency')
plt.title(r'dsitribution of returned orders')
plt.grid(True)
a = plt.axes([.75, .4, .1, .4])
sns.boxplot(x = hist_data,
           orient="v",
           palette="Set3")
plt.title('boxplot')
plt.xticks([])
plt.yticks([])

plt.show()
```


![png](/DataAnalysisonCasperData_files/output_20_0.png)



```python
def plotPie(mon):
    # Pie chart, where the slices will be ordered and plotted counter-clockwise:
    labels = np.array(["1-25 days", "25-50 days", "50-75 days", "75-100 days", "100-125 days"])  
    #autopct = np.array(['%1.1f%%']*5)
    monthist = return_day[return_day.month==mon].day_before_return
    nphist = np.histogram(monthist, 5, range=(0, 125))
    labels[nphist[0]/sum(nphist[0]) < 0.02]=" "
    #autopct[nphist[0]/sum(nphist[0]) < 0.05]=" "

    sizes = nphist[0]
    plt.pie(sizes,labels=labels,
            autopct=lambda p: '{:.1f}'.format(p)+'%' if p > 2.5 else ' ',
            shadow=True, startangle=90)
    plt.axis('equal')  # Equal aspect ratio ensures that pie is drawn as a circle.

# plot total orders component
complete = rate_eff.net_complete
returns = rate_eff.returns_o_month
width = 0.4
xpos = [0.2, 0.3, 0.4, 0.6, 0.7]
ypos = complete/800+0.07
N = 5
ind = np.arange(N)
plt.figure(figsize=(20,10))
p1 = plt.bar(ind, complete, width,
             alpha=0.6, edgecolor='k')
p2 = plt.bar(ind, returns, width,
             bottom=complete, color='#d62728',
            alpha=0.6, edgecolor='k')

plt.ylabel('total orders')
plt.title('orders')
plt.xticks(ind, ('Aug', 'Sep', 'Oct', 'Nov', 'Dec'))
plt.ylim([0, 700])
plt.legend((p1[0], p2[0]), ('net complete', 'returns on the ordered day'))
for i in range(5):
    a = plt.axes([0.16*ind[i]+0.14, ypos[i+1], 0.1, 0.3])
# Pie chart, where the slices will be ordered and plotted counter-clockwise:
    plotPie(i+8)
plt.show()
```


![png](/DataAnalysisonCasperData_files/output_21_0.png)
