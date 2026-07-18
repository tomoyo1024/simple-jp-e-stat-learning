import os
import re
from itertools import product

import pandas as pd

def _clean_header(s):
    s = str(s)
    s = re.sub(r"[\r\n]+", "", s)
    s = s.strip()
    # Replace full-width space
    return re.sub(r"[\s\u3000]+", "_", s)

def _to_numeric_loose(series):
    cleaned = series.astype(str).str.strip().replace({"-": None, "***": None})
    return pd.to_numeric(cleaned, errors="coerce")

## Remove non-leaf rows, it means the rows contain sum of leafs
def to_leaf_level(df):
    SEIREI_CODES = {
      "01100",  # 札幌市
      "04100",  # 仙台市
      "11100",  # さいたま市
      "12100",  # 千葉市
      "14100",  # 横浜市
      "14130",  # 川崎市
      "14150",  # 相模原市
      "15100",  # 新潟市
      "22100",  # 静岡市
      "22130",  # 浜松市
      "23100",  # 名古屋市
      "26100",  # 京都市
      "27100",  # 大阪市
      "27140",  # 堺市
      "28100",  # 神戸市
      "33100",  # 岡山市
      "34100",  # 広島市
      "40100",  # 北九州市
      "40130",  # 福岡市
      "43100",  # 熊本市
    }
    _AGGREGATE_SUFFIXES = ("郡", "振興局", "支庁")
    is_seirei_total = df["city_code"].isin(SEIREI_CODES)
    is_aggregate_name = df["city_name"].str.endswith(_AGGREGATE_SUFFIXES, na=False)
    keep_mask = ~(is_seirei_total | is_aggregate_name)
    return df[keep_mask].reset_index(drop=True)

def balance_panel(df, fill_value=0):
    years = sorted(df["year"].unique())
    all_codes = sorted(df["city_code"].unique())

    # 'code' map to 'name'
    name_map = (
        df.sort_values("year")
        .drop_duplicates("city_code", keep="first")
        .set_index("city_code")["city_name"]
        .to_dict()
    )

    # Grid(year, city_code) left join original
    grid = pd.DataFrame(product(years, all_codes), columns=["year", "city_code"])
    balanced = grid.merge(df, on=["year", "city_code"], how="left")

    # Fill city_name
    balanced["city_name"] = balanced["city_name"].fillna(
        balanced["city_code"].map(name_map)
    )

    # Fill zero
    id_cols = {"year", "city_code", "city_name"}
    numeric_cols = [c for c in df.columns if c not in id_cols]
    for col in numeric_cols:
        balanced[col] = balanced[col].fillna(fill_value)

    return balanced.sort_values(["year", "city_code"]).reset_index(drop=True)

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

    code6 = df_data[0].astype(str).str.strip()
    df_data["city_code"] = code6.str[:5]
    df_data["city_name"] = df_data[2].astype(str).str.strip()
    df_data = df_data[code6.str.match(r"^\d{6}$")]

    out = pd.DataFrame({
        "city_code": df_data["city_code"].values,
        "city_name": df_data["city_name"].values,
        "population": _to_numeric_loose(df_data[5]).values,
        "households": _to_numeric_loose(df_data[6]).values,
        "change": _to_numeric_loose(df_data[19]).values,
        "growth_rate": _to_numeric_loose(df_data[20]).values,
        "natural_change": _to_numeric_loose(df_data[21]).values,
        "social_change": _to_numeric_loose(df_data[23]).values,
    })
    out = out.reset_index(drop=True)
    # Add year column
    out.insert(0, "year", year)
    return out

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

    building_list = []
    for year, file_name in building_files.items():
        if not os.path.exists(file_name):
            print(f"[Building] Not found: {file_name}, skiped")
            continue
        print(f"[Building] Cleaning {year}: {file_name} ...")
        cleaned = clean_estat_building_starts(file_name, year=year)
        raw_n = len(cleaned)
        cleaned = to_leaf_level(cleaned)
        print(f" {raw_n} raw > {len(cleaned)} leaves")
        building_list.append(cleaned)

    building_panel = pd.concat(building_list, ignore_index=True)
    unbalanced_n = len(building_panel)
    building_panel = balance_panel(building_panel)
    n_b_cities = building_panel["city_code"].nunique()
    n_years = building_panel["year"].nunique()

    print(
        f"[Building] balance_panel: {unbalanced_n} > {len(building_panel)} rows"
        f"({n_b_cities} cities * {n_years} years)"
    )

    population_list = []
    for year, file_name in population_files.items():
        if not os.path.exists(file_name):
            print(f"[Population] Not found: {file_name}, skiped")
            continue
        print(f"[Population] Cleaning {year}: {file_name} ...")
        cleaned = clean_estat_population(file_name, year=year)
        population_list.append(cleaned)
