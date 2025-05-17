# Missing Values Analysis – _Ride_ Table
This is a report on the missing values of the *Ride table* and how I handled them


## Overview of Missing data
**There are 4 types of trips that miss values.**\
In total there are **71 115 trips** that have missing values in one of the fields following: **endstationname, startstationname, endtime, starttime.**
There are trips that:
1. don't have endstationname nor endtime (60 778 trips)
2. don't have endstationname (6 397 trips)
3. don't have startstationname(3 698 trips)
4. don't have startstationname nor endstationname (282 trips)


I categorized the 4 types of trips into 4 CASES *from top to bottom* for better filtering and analysis. 
+ CASE 1 and CASE 4: removed as they miss too much information to be useful
+ CASE 2 and CASE 3: investigate more for potention inclusion

## Investigation Methodology
For CASE 2 and CASE 3, a 5-step process was followed:
1. __Profiling__ affected rows based on duration, time, and available station info.
2. __Plausibility checks__ to ensure logical consistency.
3. __Comparative analysis__ with complete trips to identify anomalies or patterns to answer the question *"Are the incomplete trips anomalies or part of a pattern?"*
4. __Outlier detection__, particularly durations exceeding 24 hours 
5. __Flagging__ data quality issues using a data_quality_flag:
   * 'remove_extreme_duration'
   * 'impute station'
   * 'review'
   * 'keep'


Before investigation, please keep in mind that after 24 hours, the bike is presumed stolen and user is charged up to $2,000 according to the website of BIXI (https://bixi.com/en/how-to-use-the-bixi-service/#:~:text=Yes%2C%2024%20consecutive%20hours!,you%20are%20finished%20riding%20it.)

## Focus Analysis - CASE 2: missing endstationname (6 397 trips)
__Trip duration distribution__
| duration_range | trip_count |	percentage_of_total |
| ------- | ------- |	------- |
| 1. < 5 mins | 913 |	14 |
|2. 5-10 mins |	1847 |	29 |
|3. 11-20 mins|	1605|	25|
|4. 21-30 mins|	424|	7|
|5. 31-60 mins|	177|	3|
|6. 1-12 hours|	744|	12|
|7. 12-24 hours|	307|	5|
|8. Over 24 hours|	380|	6|

For investigation, there are 2 things to look at: trend by time (ie month, day and hour) and start station analysis.\
**1. Trend by Month:** higher proportions in fall/winter

| month | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|2023-10-01 00:00:00-04|	1450279|	2041|	0.14|
|2023-11-01 00:00:00-04|	650424|	1529|	0.24|
|2023-12-01 00:00:00-05|	95727|	122|	0.13|
|2024-01-01 00:00:00-05|	398|	1|	0.25|

**2. Trend by Hour of day:** peak between 9AM - 1PM
| hour_of_day | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|9	|49334	|66	|0.13|
|10	|125197	|349	|0.28|
|11	|341797	|503	|0.15|
|12	|604039	|755	|0.12|
|13	|451368	|529	|0.12 |

**3. Trend by Day of week:** no single day stands out significantly
| day_of_week | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|Tuesday  |	1632793|	1288|	0.08|
|Wednesday|	1698888|	1203|	0.07|

## Station-Level Analysis - CASE 2: missing endstationname (6 397 trips)
Filtered for stations with ≥2 CASE 2 trips during Sept–Jan and 9AM–1PM. One-off incidents were excluded to prevent skew.

There are 256 stations with the percentage range goes from 0.17% to 10.53%. Below are the top 4:
| startstationame | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|Natatorium (LaSalle / Rolland)|	114|	12|	10.53|
|Bélanger / des Galeries d'Anjou|	25|	2|	8.00|
|Fabre / St-Zotique|	714|	29|	4.06|
|Bourgeoys / Favard|	604|	20|	3.31|

**Recommendations:** 
- Prioritize maintenance at the following stations: 
   1. Natatorium (LaSalle / Rolland)
   2. Fabre / St-Zotique
   3. Bourgeoys / Favard
   4. Bélanger / des Galeries d'Anjou (low usage, monitor only)
- Further investigate trips in the 9AM–1PM window between Sept–Jan for recurring issues.
- Consider additional logging or alerts for stations with high failure rates.

## Focus Analysis - CASE 3: missing startstationname (3 698 trips)

