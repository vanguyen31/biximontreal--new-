import requests
import pandas as pd
import json

station_info_url = "https://gbfs.velobixi.com/gbfs/en/station_information.json"
info_data = requests.get(station_info_url).json()
stations_info = info_data["data"]["stations"]
df_info = pd.DataFrame(stations_info)
print(df_info.head())
#[5 rows x 13 columns]

station_status_url = "https://gbfs.velobixi.com/gbfs/en/station_status.json"
status_data = requests.get(station_status_url).json()
stations_status = status_data["data"]["stations"]
df_status = pd.DataFrame(stations_status)
print(df_info.head())
#[5 rows x 13 columns]

df_full = df_info.merge(df_status, on="station_id")
df_full.to_csv("bixi_full_data.csv", index=False)
df_check = pd.read_csv("bixi_full_data.csv")
print(df_check.head())
#[5 rows x 25 columns]

df_full.to_csv(r"C:\Users\path\bixi_full_data.csv", index=False)
