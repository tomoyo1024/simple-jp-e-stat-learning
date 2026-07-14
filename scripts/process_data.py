import os
import re

import pandas as pd


def clean_estat_building_starts(file_path, year):
    df_raw = pd.read_excel(file_path, header=None, engine="xlrd")

    empty_cols = [
        i
        for i in range(min(3, len(df_raw.columns)))
        if df_raw.iloc[:, i].notna().sum() == 0
    ]
    df_raw = df_raw.drop(columns=df_raw.columns[empty_cols])

    # Category row for group metrics
    row_category = df_raw.iloc[4].ffill()
    # Real metrics row
    row_metric = df_raw.iloc[5]
    # Data rows
    df_data = df_raw.iloc[7:].copy()
    # Add year column
    df_data.insert(0, "year", year)
    return df_data


def clean_estat_population(file_path, year):
    df_raw = pd.read_excel(file_path, header=None, engine="openpyxl")

    # Data rows
    df_data = df_raw.iloc[6:].copy()
    # Add year column
    df_data.insert(0, "year", year)
    return df_data

if __name__ == "__main__":
    building_files = {
        2021: "data/raw/building-starts/2021.xls",
        2022: "data/raw/building-starts/2022.xls",
        2023: "data/raw/building-starts/2023.xls",
        2024: "data/raw/building-starts/2024.xls",
        2025: "data/raw/building-starts/2025.xls",
    }
    population_files = {
        2021: "data/raw/basic-resident-register/2021.xlsx",
        2022: "data/raw/basic-resident-register/2022.xlsx",
        2023: "data/raw/basic-resident-register/2023.xlsx",
        2024: "data/raw/basic-resident-register/2024.xlsx",
        2025: "data/raw/basic-resident-register/2025.xlsx",
    }

    for year, file_name in building_files.items():
        if not os.path.exists(file_name):
            print(f"[Building] Not found: {file_name}, skiped")
            continue
        print(f"[Building] Cleaning {year}: {file_name} ...")
        cleaned = clean_estat_building_starts(file_name, year=year)

    for year, file_name in population_files.items():
        if not os.path.exists(file_name):
            print(f"[Population] Not found: {file_name}, skiped")
            continue
        print(f"[Population] Cleaning {year}: {file_name} ...")
        cleaned = clean_estat_population(file_name, year=year)
