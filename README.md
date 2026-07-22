# Overview

This project uses data on new buildings and the resident registry from Statistics Japan for the period 2021–2025 to investigate the impact of urban building structures on population changes. It aims to identify the building types or combinations that have the greatest impact on population through supervised learning techniques.

## Data source

### Building starts

| Year | URL |
|------|-----|
| 2021 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00600120&tstat=000001016965&cycle=7&year=20210&month=0&stat_infid=000032166778&result_back=1&tclass1val=0> |
| 2022 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00600120&tstat=000001016965&cycle=7&year=20210&month=0&stat_infid=000032166778&result_back=1&tclass1val=0> |
| 2023 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00600120&tstat=000001016965&cycle=7&year=20230&month=0&stat_infid=000040140083&result_back=1&cycle_facet=cycle&tclass1val=0&metadata=1&data=1> |
| 2024 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00600120&tstat=000001016965&cycle=7&year=20240&month=0&stat_infid=000040247010&result_back=1&cycle_facet=cycle&tclass1val=0&metadata=1&data=1> |
| 2025 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00600120&tstat=000001016965&cycle=7&year=20250&month=0&stat_infid=000040405892&result_back=1&cycle_facet=cycle&tclass1val=0&metadata=1&data=1> |

### Basic Resident Register

| Year | URL |
|------|-----|
| 2021 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200241&bunya_l=02&tstat=000001039591&cycle=7&year=20210&month=0&tclass1=000001039601&stat_infid=000040306659&result_back=1&cycle_facet=tclass1%3Acycle&tclass2val=0&metadata=1&data=1> |
| 2022 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200241&bunya_l=02&tstat=000001039591&cycle=7&year=20220&month=0&tclass1=000001039601&stat_infid=000032224636&result_back=1&cycle_facet=tclass1%3Acycle&tclass2val=0&metadata=1&data=1> |
| 2023 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200241&bunya_l=02&tstat=000001039591&cycle=7&year=20230&month=0&tclass1=000001039601&stat_infid=000040306647&result_back=1&cycle_facet=tclass1%3Acycle&tclass2val=0&metadata=1&data=1> |
| 2024 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200241&bunya_l=02&tstat=000001039591&cycle=7&year=20240&month=0&tclass1=000001039601&stat_infid=000040306672&result_back=1&cycle_facet=tclass1%3Acycle&tclass2val=0&metadata=1&data=1> |
| 2025 | <https://www.e-stat.go.jp/stat-search/files?page=1&layout=datalist&toukei=00200241&bunya_l=02&tstat=000001039591&cycle=7&year=20250&month=0&tclass1=000001039601&stat_infid=000040306653&result_back=1&cycle_facet=tclass1%3Acycle&tclass2val=0&metadata=1&data=1> |

## Process

"scripts/process_data.py"

Statistics Japan officially distributes data in XLS and XLSX formats and does not provide a universal format, so a script must be written to process the data. Python was used instead of R to facilitate processing of the XLS format.

In addition, the data contains certain issues related to Japan's administrative divisions, which also need to be addressed in the script.

- Exclude aggregate rows, since their subordinate entities are already included.
- Balance the building stat, replace missing values with 0.
- Merge building and population stat(prefix: `pop_`) using year and city_code(inner join).

Output file: `data/cleaned_panel_2021_2025.csv`

## Implementation

### Exploratory Data Analysis

### Modeling
