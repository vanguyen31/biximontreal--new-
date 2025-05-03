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
As CASE 1 and CASE 4 miss too much information for it to be useful I remove them from the dataset. At the same time, I investigate CASE 2 and CASE 3 further. 

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
   
