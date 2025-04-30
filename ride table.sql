CREATE TABLE rides (
	STARTSTATIONNAME TEXT,
	STARTSTATIONARRONDISSEMENT TEXT,
	STARTSTATIONLATITUDE NUMERIC,
	STARTSTATIONLONGITUDE NUMERIC,
	ENDSTATIONNAME TEXT,
	ENDSTATIONARRONDISSEMENT TEXT,
  	ENDSTATIONLATITUDE NUMERIC,
  	ENDSTATIONLONGITUDE NUMERIC,
  	STARTTIMEMS bigint,
  	ENDTIMEMS bigint
);

COPY rides(
	STARTSTATIONNAME, 
	STARTSTATIONARRONDISSEMENT, 
	STARTSTATIONLATITUDE, 
	STARTSTATIONLONGITUDE, 
	ENDSTATIONNAME, 
	ENDSTATIONARRONDISSEMENT, 
	ENDSTATIONLATITUDE,
	ENDSTATIONLONGITUDE, 
	STARTTIMEMS,
	ENDTIMEMS)
FROM 'C:\Users\nguye\Documents\CONCORDIA\personal project\DonneesOuvertes2023_12/DonneesOuvertes (1).csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';


ALTER TABLE rides
ALTER COLUMN starttimems TYPE timestamptz USING to_timestamp(starttimems::float8/1000) AT time zone 'UTC';
ALTER TABLE rides
ALTER COLUMN endtimems TYPE timestamptz USING to_timestamp(endtimems::float8/1000) AT time zone 'UTC';

ALTER TABLE rides
RENAME COLUMN starttimems TO starttime;
ALTER TABLE rides
RENAME COLUMN endtimems TO endtime;

--To have proper analysis, I ran the following queries to visualize the missing values
--The following queries are used to view all trips with missing values.
SELECT count (*) FROM rides
WHERE STARTSTATIONNAME IS NULL
or ENDSTATIONNAME IS NULL
or STARTTIME IS NULL
or ENDTIME IS NULL

--I ran variations of these queries to see the number of trips of 4 different value missing cases
SELECT count (*) FROM rides
WHERE STARTSTATIONAME IS NULL
and ENDSTATIONNAME IS not NULL
and ENDTIME IS NULL
and STARTTIME IS not NULL

/* there are 4 cases of missing values.
in total there are 71 115 trips that have missing values in one of the fields above.
there are trips that:
(1) don't have endstationname nor endtime (60 778)
(2) don't have endstationname (6 397)
(3) don't have startstationname(3 698)
(4) don't have startstationname nor endstationname (282)
*/

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

/*
to investigate CASE 2 (missing endstationanme) and CASE 3 (missing startstationname),
there are several things I wanna look at.
First, I wanna check the duration to see if there are any abnormal durations (ie too short or too long)
*/
ALTER TABLE rides
ADD COLUMN duration_minutes INT;

UPDATE rides
SET duration_minutes = FLOOR (EXTRACT(EPOCH FROM (endtime-starttime))/60);

--CASE 2: miss endstation
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
/*
The outcome told me that most of the trips last between 5-20 minutes. 
There are 307 trips that last from 12-24 hours,
and 380 trips that last over 24 hours, which is considered stolen according to BIXI website
(https://bixi.com/en/how-to-use-the-bixi-service/#:~:text=Yes%2C%2024%20consecutive%20hours!,you%20are%20finished%20riding%20it.)
*/

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
Very likely that it's an external problems (ie stealing). 
*/



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