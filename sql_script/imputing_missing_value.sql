--I ran variations of these queries to see the number of trips of 4 different value missing cases
SELECT count (*) FROM rides
WHERE STARTSTATIONAME IS NULL
and ENDSTATIONNAME IS not NULL
and ENDTIME IS NULL
and STARTTIME IS not NULL

--I created a column to flag the cases
ALTER TABLE rides
ADD COLUMN missing_value_cases TEXT;

UPDATE rides
SET missing_value_cases = CASE

		WHEN endstationname IS NULL AND endtime IS NULL 
		AND startstationname IS NOT NULL AND starttime IS NOT NULL
		THEN 'CASE 1'
		
		WHEN endstationname IS NULL
		AND endtime IS NOT NULL AND startstationname IS NOT NULL
		AND starttime IS NOT NULL
		THEN 'CASE 2'
		
		WHEN startstationname IS NULL
		AND endstationname IS NOT NULL AND endtime IS NOT NULL
		AND starttime IS NOT NULL
		THEN 'CASE 3'
		
		WHEN endstationname IS NULL AND startstationname IS NULL 
		AND endtime IS NOT NULL AND starttime IS NOT NULL
		THEN 'CASE 4'
		
		ELSE NULL
END;

/*
As case 1 and 4 miss too much information for it to be useful
I removed them from the dataset
*/
DELETE FROM rides
WHERE missing_value_cases IN ('CASE 1', 'CASE 4');

--I created a column of duration in minutes
ALTER TABLE rides
ADD COLUMN duration_minutes INT;

UPDATE rides
SET duration_minutes = FLOOR (EXTRACT(EPOCH FROM (endtime-starttime))/60);

--CASE 2: miss endstation
--I categorized the trips in case 2 by the duration range asc
SELECT 
  CASE 
    WHEN duration_minutes < 5 THEN '1. Under 5 mins'
    WHEN duration_minutes BETWEEN 5 AND 10 THEN '2. 5-10 mins'
    WHEN duration_minutes BETWEEN 11 AND 20 THEN '3. 11-20 mins'
    WHEN duration_minutes BETWEEN 21 AND 30 THEN '4. 21-30 mins'
    WHEN duration_minutes BETWEEN 31 AND 60 THEN '5. 31-60 mins'
	WHEN duration_minutes BETWEEN 61 AND 360 THEN '6. 1-6 hours'
	WHEN duration_minutes BETWEEN 361 AND 720 THEN '7. 6-12 hours'
	WHEN duration_minutes BETWEEN 721 AND 1440 THEN '8. 12-24 hours'
    ELSE '9. Over 24 hours'
  END AS duration_range,
  COUNT(*) AS trip_count
FROM rides
WHERE missing_value_cases = 'CASE 2'
GROUP BY duration_range
ORDER BY duration_range asc;

--I counted the number of case 2 trips vs total number of trips by months
select 
	to_char (starttime, 'YYYY-MM') as year_month,
	count (*) as total_trips,
	sum (case when missing_value_cases = 'CASE 2' then 1 else 0 end) as case_2_trips,
	round(
		sum (case when missing_value_cases = 'CASE 2' then 1 else 0 end)*100.0/count (*),2
	) as percent_case_2
from 
	rides
group by 
	to_char (starttime, 'YYYY-MM')
order by 
	year_month asc;






SELECT COUNT(*) as count_trip_over_24_hours, startstationname, startstationarrondissement
from rides
where duration_minutes >1440
and missing_value_cases ='CASE 2'
GROUP BY startstationname, startstationarrondissement
order by count_trip_over_24_hours
/*
There are 18 boroughs that have trips over 1440 minutes.
Among them, there are Le Plateau Mt Royal with 12 times, 
Rosemont La Petite Patrie - 8 times, 
Ville_Marie - 18 times.
Given then Le Plateau and Rosemont are the 2 the most popular areas
and Ville-Marie is the largest borough on the island, the incident is more likely to happen
whether it's caused by system errors or the bikes were stole.
*/

SELECT trip_count_over_24h, COUNT(*) AS number_of_stations
FROM (
  SELECT startstationname, COUNT(*) AS trip_count_over_24h
  FROM rides
  WHERE duration_minutes > 1440
    AND missing_value_cases = 'CASE 2'
  GROUP BY startstationname
) AS station_trip_counts
GROUP BY trip_count_over_24h
ORDER BY trip_count_over_24h;

/*
There are 205 stations that had trips over 1440 minutes once. 
These can be considered system errors. 
Possible explanation is that people did not dock the bike properly (customer at fault)
There is 1 dock that the incident happens 5 times (Guy/Ste Catherine). This could be a dock related error
*/

--CASE 3: miss startstation
SELECT 
  CASE 
    WHEN duration_minutes < 5 THEN '1. Under 5 mins'
    WHEN duration_minutes BETWEEN 5 AND 10 THEN '2. 5-10 mins'
    WHEN duration_minutes BETWEEN 11 AND 20 THEN '3. 11-20 mins'
    WHEN duration_minutes BETWEEN 21 AND 30 THEN '4. 21-30 mins'
    WHEN duration_minutes BETWEEN 31 AND 60 THEN '5. 31-60 mins'
	WHEN duration_minutes BETWEEN 61 AND 1440 THEN '6. 1-24 hours'
    ELSE '8. Over 24 hours'
  END AS duration_range,
  COUNT(*) AS trip_count
FROM rides
WHERE missing_value_cases = 'CASE 3'
GROUP BY duration_range
ORDER BY duration_range asc;
/*
The outcome showed that most trips last around 5-10 minutes. 
There are 3 trips that last over 1 day
*/

SELECT COUNT(*) as count_trip_over_24_hours, endstationname, endstationarrondissement
from rides
where duration_minutes >1440
and missing_value_cases ='CASE 3'
GROUP BY endstationname, endstationarrondissement
order by count_trip_over_24_hours
/*
there are 3 docks in 3 different areas that have 1 trip over 24 hours.
The possible explanation includes but not limited to: 
malfunction system at dock (ie faulty RFID tag, sensor, or network lag.), 
Maintenance staff might have redeployed the bike manually without scanning it into the system.
*/

--I filted out the trips with missing values into 3 categories: to be removed(due to abnormally long duration), to be imputed the station, to be reviewed
SELECT *,
  CASE
    WHEN missing_value_cases = 'CASE 2' AND duration_minutes > 1440 THEN 'remove_extreme_duration'
    WHEN missing_value_cases = 'CASE 2' AND duration_minutes <= 720 THEN 'impute_endstation'
    WHEN missing_value_cases = 'CASE 2' THEN 'review'

    WHEN missing_value_cases = 'CASE 3' AND duration_minutes > 1440 THEN 'remove_extreme_duration'
    WHEN missing_value_cases = 'CASE 3' AND duration_minutes <= 30 THEN 'impute_startstation'
    WHEN missing_value_cases = 'CASE 3' THEN 'review'

    ELSE 'keep'
  END AS data_quality_flag
FROM rides;

/* (draft add this later)
-- CASE 2: For missing endstationname, find common destinations for same startstation & similar duration
SELECT endstationname, COUNT(*) AS frequency
FROM rides
WHERE startstationname = 'St-Denis / Ste-Catherine'
  AND ABS(EXTRACT(EPOCH FROM (endtime - starttime)) / 60) 
  AND endstationname IS NOT NULL
GROUP BY endstationname
ORDER BY frequency DESC
LIMIT 5;
/*
