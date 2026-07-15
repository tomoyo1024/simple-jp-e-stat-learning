import os
import re

import pandas as pd

def _clean_header(s):
    s = str(s)
    s = re.sub(r"[\r\n]+", "", s)
    s = s.strip()
    # Replace full-width space
    return re.sub(r"[\s\u3000]+", "_", s)

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

    new_columns = ["city_combined"]
    for i in range(1, len(df_raw.columns)):
        cat_name = _clean_header(row_category.iloc[i])
        metric_name = _clean_header(row_metric.iloc[i])
        new_columns.append(f"{cat_name}_{metric_name}")
    # Data rows
    df_data = df_raw.iloc[7:].copy()   
    df_data.columns = new_columns

    # Spliting
    combined = df_data["city_combined"].astype(str).str.strip()
    extracted = combined.str.extract(r"^(\d{5,6})(.*)$")
    df_data.insert(0, "city_code", extracted[0].values)
    df_data.insert(1, "city_name", extracted[1].values)
    df_data = df_data.drop(columns=["city_combined"])
    df_data = df_data[df_data["city_code"].notna()]

    for col in new_columns[1:]:
        df_data[col] = df_data[col].astype(str).str.strip().replace("-", "0")
        df_data[col] = pd.to_numeric(df_data[col], errors="coerce").fillna(0)

    # Add year column
    df_data.insert(0, "year", year)
    df_data = df_data.reset_index(drop=True)
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
