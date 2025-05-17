This is a report on the missing values of the *Ride table* and how I handled them:
\
\
**There are 4 types of trips that miss values.**\
In total there are **71 115 trips** that have missing values in one of the fields following: **endstationname, startstationname, endtime, starttime.**
There are trips that:
1. don't have endstationname nor endtime (60 778 trips)
2. don't have endstationname (6 397 trips)
3. don't have startstationname(3 698 trips)
4. don't have startstationname nor endstationname (282 trips)


I categorized the 4 types of trips into 4 CASES *from top to bottom* for better filtering and analysis. \
CASE 1 and CASE 4: removed as they miss too much information to be useful
CASE 2 and CASE 3: investigate more

**4 steps are done for investigation:**
1. Profile the affected rows: looking at other fields for trips with missing data
   * Duration
   * Time
   * Start or End station (if available)
2. Access plausibility to see if the logic is consistent
3. Compare with complete trips to answer the question *"Are the incomplete trips anomalies or part of a pattern?"*
4. Investigate outliers (ie those with durations > 1440 minutes/24 hours)
5. Create a data_quality_flag
   * 'remove_extreme_duration'
   * 'impute station'
   * 'review'
   * 'keep'


Before investigation, please keep in mind that after 24 hours, the bike is presumed stolen and user is charged up to $2,000 according to the website of BIXI (https://bixi.com/en/how-to-use-the-bixi-service/#:~:text=Yes%2C%2024%20consecutive%20hours!,you%20are%20finished%20riding%20it.)


**CASE 2: missing endstationname (6 397 trips)**
I categorize the trips by duration range:
| duration_range | trip_count |	percentage_of_total |
| ------- | ------- |	------- |
| 1. Under 5 mins | 913 |	14 |
|2. 5-10 mins |	1847 |	29 |
|3. 11-20 mins|	1605|	25|
|4. 21-30 mins|	424|	7|
|5. 31-60 mins|	177|	3|
|6. 1-12 hours|	744|	12|
|7. 12-24 hours|	307|	5|
|8. Over 24 hours|	380|	6|

For investigation, there are 2 things to look at: trend by time (ie month, day and hour) and start station analysis.\
**1. Trend by Month:**

| month | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|2023-04-01 00:00:00-04|	667563|	220|	0.03|
|2023-05-01 00:00:00-04|	1578155|	250|	0.02|
|2023-06-01 00:00:00-04|	1674507|	301|	0.02|
|2023-07-01 00:00:00-04|	1823788|	210|	0.01|
|2023-08-01 00:00:00-04|	1864361|	608|	0.03|
|2023-09-01 00:00:00-04|	1924600|	1115|	0.06|
|2023-10-01 00:00:00-04|	1450279|	2041|	0.14|
|2023-11-01 00:00:00-04|	650424|	1529|	0.24|
|2023-12-01 00:00:00-05|	95727|	122|	0.13|
|2024-01-01 00:00:00-05|	398|	1|	0.25|

**Key takeaway:** Oct, Nov, Dec and Jan of 2024 witnessed higher proportion of trips with missing endstationname.

**2. Trend by Hour of day:**
| hour_of_day | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|10	|125197	|349	|0.28|
|11	|341797	|503	|0.15|
|9	|49334	|66	|0.13|
|12	|604039	|755	|0.12|
|13	|451368	|529	|0.12 |
|14	|419519	|366	|0.09|
|7	|85074	|56	|0.07|
|16	|613160	|365	|0.06|
|15	|511875	|323	|0.06|
|8	|43982	|24	|0.05|
|17	|639501	|288	|0.05|
|5	|167704	|81	|0.05|
|0	|647611	|263	|0.04|
|1	|530359	|218	|0.04|
|2	|443398	|165	|0.04|
|4	|247650	|107	|0.04|
|6	|112693	|44	|0.04|
|18	|659747	|251	|0.04|
|19	|763491	|294	|0.04|
|23	|806664	|242	|0.03|
|20	|954809	|301	|0.03|
|21	|1155112	|386	|0.03|
|3	|360396	|105	|0.03|
|22	|995322	|316	|0.03|

**Key takeaway:** 9AM - 1PM is the time range with the highest likelihood of trips with missing endstationname. 

**3. Trend by Day of week:**
| day_of_week | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|Tuesday  |	1632793|	1288|	0.08|
|Wednesday|	1698888|	1203|	0.07|
|Thursday |	1741812|	1080|	0.06|
|Monday   |	1492410|	819|	0.05|
|Friday   |	1827299|	957|	0.05|
|Saturday |	1739786|	676|	0.04|
|Sunday   |	1596814|	374|	0.02|

**Key takeaway:** There is no specific day that has a concentrated amount of CASE 2 trips. 

Now that I identified the trends by time, I would investigate further by looking at the start stations that have trips within the time range of 9AM-1PM and month range of Sept-Jan.\
High proportion of such trips in any stations indicates high likelihood of system errors of the dock. \
To prevent skew in small-sample data, I removed stations that the incident happended once. I compared the amount case_2_trips with the amount of total_trips in mentioned time frames.\
There are 256 stations with the percentage range goes from 0.17% to 10.53%. Below are the top 4:
| startstationame | total_trips | case_2_trips | percent_case_2 |
| -------| ------- | ------- | ------- |
|Natatorium (LaSalle / Rolland)|	114|	12|	10.53|
|Bélanger / des Galeries d'Anjou|	25|	2|	8.00|
|Fabre / St-Zotique|	714|	29|	4.06|
|Bourgeoys / Favard|	604|	20|	3.31|

**Key takeaway:** 
- There are 3 docks that have high volumes of trips during the specified time periods, espcially Natatorium (LaSalle / Rolland) which also has huge amount of Case 2 trips.
- Bélanger / des Galeries d'Anjou has high percentage yet the amount of total usage is not really noticeable.
- The priority of maintenance should be 1 - 3 - 4 - 2 given that the stations are placed in the order of ascending number.
