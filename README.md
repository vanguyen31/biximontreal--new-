# BIXI Operations Insights: Simulated Data Analysis Using SQL and Power BI
Leveraged BIXI’s open data (https://bixi.com/en/open-data/) to create assumption-based relational database in PostgreSQL and a dynamic Power BI dashboard, providing insights into usage patterns, maintenance needs, and system optimization. (On-going project)
<br>
# Project Overview:
## Context

**As of January 1st, 2025, BIXI Montréal began offering year-round service, including the winter months, following the success of its pilot project** (**Source**: https://bixi.com/en/bixi-year-round/). This expansion emphasizes the need for accurate data management and a deep understanding of user preferences and seasonal patterns. More specifically, it is crucial to ensure that stations remain adequately stocked with bikes, identify high-demand areas, and adjust operations accordingly to maintain service quality and meet user expectations throughout the year.

**Data Description**

To make sure that the data is relevant, I picked the dataset of 2023. (That of 2024 failed to open). The table includes +11 M rows and 10 columns:

**1. StartStationName** i.e St-Hubert / de Maisonneuve (sud)
<br>
**2. StartArrondissment** i.e Ville-Marie
<br>
**3. StartStationLatitude** i.e 45.5158684
<br>
**4. StartStationLongtitude** i.e -73.5600838
<br>
**5. EndStationName** i.e Place d'Youville / McGil
<br>
**6. EndArrondissment** i.e Ville-Marie
<br>
**7. EndStationLatitude** i.e 45.4999647
<br>
**8. EndStationLongtitude** i.e -73.5561544
<br>
**9. StartTimeMs** i.e 1.68139E+12	
<br>
**10. EndTimeMs** i.e	1.68139E+12
<br>

## Project Workflow

**Data Acquisition & Exploration** 

  * Downloaded raw CSV files containing millions of trip records.

  * Reviewed schema for relevant attributes: start/end times, station IDs, membership status, trip duration.

**Data Preprocessing & Cleaning (SQL)** 

  * Handled missing and inconsistent data entries (e.g., null station names, negative durations).

  * Normalized timestamps, standardized location formats, and created derived fields (e.g., day of week, ride length in minutes).

  * Merged station metadata to enrich trip records with location details.

**Exploratory Data Analysis (SQL)**

  * Queried trends over time, such as monthly usage and differences between member and casual users.

  * Calculated KPIs: average trip duration, most/least used stations, peak hours, and trip frequency by weekday.

  * Identified seasonal trends and anomalies (e.g., drastic drops or spikes in ridership).

**Data Visualization (Power BI)** : Built interactive dashboards highlighting:

  * Rider demographics and membership patterns.

  * Station heatmaps by usage frequency.

  * Time-based visualizations (hourly, daily, seasonal).

  * Included slicers and filters to let users explore specific neighborhoods or time frames.

## Key Findings
*(coming soon)*


## Business Value & Recommendations
*(coming soon)*

