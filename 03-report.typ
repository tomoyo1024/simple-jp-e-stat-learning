#import "@preview/charged-ieee:0.1.4": ieee

#show: ieee.with(
  title: [Municipal Construction Industry Structure and Population Change: Predictive Modeling with e-Stat Panel Data],
  abstract: [
    Against the backdrop of Japan’s low birth rate and aging population, forecasting population growth or decline in municipalities is of great significance for local governance and the allocation of public resources. Based on e-Stat statistics on building starts and panel data from the Basic Resident Register for 2021–2025, this study examines whether the industrial structure of new construction in municipalities (the proportion of floor area by use, with composite data where the sum equals 1) can predict their population growth or decline rates. The analysis is limited to actual municipalities with populations exceeding 10,000 (6,819 municipality-year observations covering 1,378 municipalities). Two dimension-reduction approaches were compared: linear regression after manually consolidating 18 detailed building categories into 4 broad categories based on industrial classification, and Lasso regression directly applied to 17 detailed categories (algorithmic dimension reduction). To avoid leakage caused by observations from the same municipality across different years being included in both the training and testing sets in panel data, cross-validation grouped by municipality was employed throughout the analysis.
    The results indicate that the construction industry structure possesses robust cross-municipality predictive power for population growth or decline: under group-based cross-validation, the test R² values for the broad-category regression and the detailed-category Lasso regression were approximately 0.13 and 0.21, respectively, and the trends were highly consistent—the share of real estate and mixed residential-commercial use was associated with population growth, while the share of agriculture and mining was associated with population outflow. After introducing per capita construction intensity (scale dimension), predictive power increased significantly (R² ≈ 0.43); a time lag test showed that the R² (0.436) for predicting the following year’s population change based on the current year’s construction structure was not lower than that for the same period (0.426), indicating that construction intensity is a leading indicator on the supply side.
  ],
  authors: (
    (
      name: "YANKAI MA",
      department: [],
      organization: [],
      location: [],
      email: "",
    ),
  ),
  index-terms: (
    "Population change prediction",
    "Construction Industry Structure",
    "Compositional data",
    "Lasso regression",
    "Grouped cross-validation",
  ),
)

#set text(font: ("New Computer Modern", "Noto Serif CJK SC"))

= Introduction

Japan is facing a profound crisis of low birth rates and an aging population, and population decline at the local government level (cities, towns, and villages) has become a central issue for national governance and local administration. Population changes directly affect the tax base, the allocation of public services, and the continued operation of schools and medical facilities; therefore, accurately forecasting population growth rates in cities, towns, and villages is of great significance for local governance and the allocation of public resources.

The central research question of this study is: *Can the industrial structure of newly constructed buildings in municipalities (the composition of floor area by use) be used to predict their population growth rates?* The structure of building uses reflects the characteristics of economic activity, land-use patterns, and development potential in a given area, and thus may contain predictive information regarding the direction of population flows.

This study employs methods such as linear regression, Lasso regularization, and cross-validation as its theoretical framework. Methodologically, it compares two approaches to dimensionality reduction. The first is “manual dimension reduction”: based on industry knowledge, the 18 building subcategories were manually aggregated into broader categories before performing OLS regression. The second is “algorithmic dimension reduction”: Lasso-regularized regression was performed directly on the subcategories, with variable selection automatically handled by the algorithm. It should be emphasized that this study is a forecasting task rather than a causal analysis—the focus here is on the statistical association between the composition of floor area and population growth rates, as well as out-of-sample predictive power.

= Data Processing


This study uses two data sources, both from the e-Stat portal of the Statistics Bureau of Japan’s Ministry of Internal Affairs and Communications. The first is the Survey on Building Starts, which records the floor area of new buildings by use in each municipality. The file format is `.xls`, and the `xlrd` library is used to read it. The second is the Basic Resident Register, which records the population and population changes for each municipality. The file format is `.xlsx`, and it is read using the `openpyxl` library.

The data cleaning pipeline is located in `scripts/process_data.py`, and the main steps are as follows. First, Excel parsing: The construction data table header has a two-level structure (the category row is at index 4, the indicator row is at index 5, and the data starts from row 7), while the population data is extracted from fixed columns. Second, code and name extraction: The building data merges municipality codes and names into a single column, which is then split using regular expressions into 5–6-digit numeric codes and name text. Third, leaf-level municipality extraction: Rows ending with `000` (prefectural summary rows), city-level summaries for the 20 government-designated cities, and county-level summary rows ending with “郡,” “振興局,” or “支庁” are excluded. Additionally, panel balancing was performed by constructing a complete grid of year $times$ municipality code and filling missing values with 0. Finally, the building and population data were merged via an inner join on `(year, city_code)`.

Government-designated cities are subdivided into “wards,” and ward-level data is retained as leaf-level observations; original missing values, denoted by `“-”`, are uniformly replaced with $0$. The final output, `data/cleaned_panel_2021_2025.csv`, contains 47 columns (3 identifier variables + 38 building area indicators + 6 population indicators).

= Data Analysis


The distribution of the dependent variable `pop_growth_rate` (population growth rate) generally shows negative growth, with a median of approximately $-1.2%$, but it has long tails on both sides, with a maximum value exceeding $+20%$ and a minimum value below $-18%$. Box plots grouped by population size confirm this: the smaller the population of a town or village, the greater the variance in the growth rate (even a small number of people moving in or out causes significant fluctuations), which means that the Y-values for small towns and villages are subject to extremely high noise.

Sample selection is a critical decision in this analysis. The full dataset consists of 9,349 rows (1896 municipalities); after restricting the sample to those with a population $> 10,000$, 6,819 rows (1378 municipalities) remain, representing approximately 73% of the original dataset. The table below directly illustrates the benefits of this restriction—it shows the $R^2$ values from tests using grouped Lasso ($lambda_("min")$) on the three Y components for different population thresholds.

#figure(
  table(
    columns: 4,
    align: center,
    table.hline(stroke: 0.8pt),
    table.header([Lower Population Threshold], [Total Change$R^2$], [Natural Change$R^2$], [Social Change$R^2$]),
    table.hline(stroke: 0.5pt),
    [0 (Full sample)], [0.127], [0.129], [0.064],
    [10000], [0.251], [0.212], [0.156],
    table.hline(stroke: 0.5pt),
  ),
  caption: [Goodness of Fit at Different Population Thresholds ($lambda_("min")$)],
) <tab:threshold>


For feature extraction, 18 ratio variables `p_*` were constructed from 38 columns of floor area metrics; each variable represents the ratio of the area of a specific land use category to the total area, and the sum of the 18 ratios exactly equals 1 (due to the component data and simplex constraints). We then performed a preliminary screening using Pearson’s correlation coefficient between each `p_*` and Y to identify the building use types most strongly associated with population growth or decline.

= Model Training

In the feature engineering phase of this study, a coarse-clustering strategy (“artificial principal component analysis”) was employed to group the 18 subcategories (A–R) into 5 broad categories based on their industrial significance; the residential category was discarded as the reference to eliminate complete multicollinearity in the component data.

#figure(
  table(
    columns: 3,
    align: (left, left, left),
    table.hline(stroke: 0.8pt),
    table.header([*Broad categories*], [*subcategories*], [*Meaning of the Industry*]),
    table.hline(stroke: 0.5pt),
    [Residential (reference, dropped)], [A\ B\ C], [Detached, semi-residential, mixed residential-commercial],
    [Primary], [D], [Agriculture, forestry, fisheries],
    [Secondary], [E\ F\ G\ H\ I], [Mining, manufacturing, energy, telecom, transport],
    [Tertiary / Services], [J\ K\ L\ M\ N\ O\ P], [Retail, finance, real estate, accommodation, education, healthcare, other services],
    [Public / Other], [Q\ R], [Government, unclassified],
    table.hline(stroke: 0.5pt),
  ),
  caption: [Aggregation scheme: 18 building subcategories into 5 broad categories],
) <tab:coarse>

Approach A uses OLS regression with four broad categories. The coefficients are: `s_primary` $-4.09$ (largest absolute value, agriculture, forestry, and fisheries), `s_public_other` $-3.14$ (public services/unclassified), `s_tertiary` $-0.84$ (business services), and `s_secondary` $-0.59$ (mining, energy, and transportation). All four coefficients are significantly negative, and the implication is clear: a higher share of residential construction is associated with a higher population growth rate; any industry that takes market share away from residential construction is associated with lower population growth.

Approach B uses Lasso regression with 17 subcategories (excluding `p_living`). The $lambda_("1se")$ model identifies 13 industries: on the positive side, `real_estate` ($+4.29$), `mixed_use` ($+2.52$), and `logis` ($+0.60$); negative effects include `mining` ($-3.88$), `agri` ($-2.99$), `other_type` ($-2.30$), and `official` ($-1.77$).

In addition, the per capita building density feature was introduced as a scale dimension, calculated using the formula $log(1 + "total_building_area" / "population")$. This feature shows almost no correlation with population size ($r approx 0.08$), but is correlated with the growth rate ($r = 0.41$; $R^2 approx 0.17$). The explanatory power of this single feature alone exceeds half the combined explanatory power of the 17 ratio features. The evaluation metric uniformly uses the test set $R^2$.

= Model Validation

The panel data poses a risk of data leakage: rows spanning multiple years for the same municipality may end up in both the training set and the test set. The solution is to group the data by `city_code` (so that all years for a given municipality are on the same side), and the cross-validation (CV) used for Lasso’s internal $lambda$ selection must also be grouped (with `foldid` assigned by municipality).


#figure(
  table(
    columns: 3,
    align: center,
    table.hline(stroke: 0.8pt),
    table.header([*Model*], [*Random Split $R^2$*], [*Grouped Split $R^2$*]),
    table.hline(stroke: 0.5pt),
    [Approach A (4 broad OLS)], [0.104], [0.134],
    [Approach B (17 fine lasso)], [0.175], [0.211],
    table.hline(stroke: 0.5pt),
  ),
  caption: [Test-set $R^2$: random vs. grouped split],
) <tab:cv>


The key finding is that the group-based $R^2$ is actually *higher* than the random $R^2$, indicating that the model captures genuine cross-municipality patterns rather than a memory of cross-year patterns within the same city.


The time lag test is used to address reverse causality (i.e., population inflows driving construction in the same year, thereby exaggerating the correlation during that period). Using the $X_t -> Y_{t+1}$ setup, the lagged dataset consists of 5,441 rows (base years 2021–2024). The $R^2$ for the concurrent period is $0.211$, while the $R^2$ for the lagged period is $0.192$—a decrease of only about 9%—and the selected variables show a high degree of overlap.

= Model Performance

The introduction of strength features doubled the $R^2$ for both sets of models.

#figure(
  table(
    columns: 3,
    align: center,
    table.hline(stroke: 0.8pt),
    table.header([*Model*], [*Proportions only*], [*+ Intensity*]),
    table.hline(stroke: 0.5pt),
    [Approach A (4 broad categories)], [0.134], [0.44],
    [Approach B (17 fine lasso)], [0.211], [0.426],
    table.hline(stroke: 0.5pt),
  ),
  caption: [Impact of intensity feature on performance (grouped CV)],
) <tab:intensity>


The table below provides a further comparison between concurrent and lagged forecasts (Approach B).

#figure(
  table(
    columns: 3,
    align: center,
    table.hline(stroke: 0.8pt),
    table.header([], [*Proportions only*], [*+ Intensity*]),
    table.hline(stroke: 0.5pt),
    [Same period ($X_t$, $Y_t$)], [0.211], [0.426],
    [Lagged ($X_t$, $Y_(t+1)$)], [0.192], [0.436],
    table.hline(stroke: 0.5pt),
  ),
  caption: [Same-period vs. lagged performance (Approach B)],
) <tab:lag>

The lagged $R^2$ (0.436) is *at least as high as* the $R^2$ for the same period (0.426). This rules out the explanation that “the high $R^2$ for the same period is due to reverse causality”—if the population influx in a given year drives construction in that same year ($Y -> X$), it indicates that construction intensity is a *leading indicator* on the supply side (building construction $->$ business recruitment $->$ population arrival the following year).

= Conclusion

== Positive findings
First, the structural composition of the construction industry has genuine predictive power for population growth rates across municipalities (with $R^2$ ranging from 0.13 to 0.21 under grouped CV); second, per capita construction intensity is the strongest predictor and serves as a leading indicator; when included, $R^2$ rises to approximately 0.43; third, manual dimensionality reduction and algorithmic dimensionality reduction show a high degree of consistency in their results.

== Limitations and Risks
First, the $R^2$ value is moderate and falls far short of providing deterministic predictions; second, there is endogeneity—residential and development variables may exhibit reverse causality ($Y -> X$), and negative variables may introduce confounding (rural decline drives both a decrease in construction and population outflow); third, this study focuses on prediction rather than causal identification.

== Improvement
Introduce nonlinear methods (Random Forest / XGBoost, Chapter 8 of ISLR2) to capture threshold effects and interactions; perform an industry-specific decomposition of economic strength; and incorporate external variables such as income and employment. Note that the conclusions are limited to Japanese municipalities with a population of $> 10,000$ and do not apply to remote, small settlements.

= Data Sources

+ Building starts: e-Stat Building Starts Survey (建築着工統計調査), #link("https://www.e-stat.go.jp/stat-search/files?toukei=00600120")[data page]
+ Basic Resident Register: e-Stat Population and Households (住民基本台帳), #link("https://www.e-stat.go.jp/stat-search/files?toukei=00200241")[data page]

Full download links for each year are listed in the project's `README.md`. Data covers fiscal years 2021--2025, distributed in XLS / XLSX format.

= Source Code

+ `scripts/process_data.py` — Python data cleaning pipeline (pandas, xlrd, openpyxl)
+ `01-eda.Rmd` — R exploratory data analysis (tidyverse, corrr, patchwork)
+ `02-modeling.Rmd` — R modeling (tidyverse, glmnet, broom)
+ Environment: R 4.6.1, Python 3, all code open-source
+ Output: `data/cleaned_panel_2021_2025.csv`

= References

+ James, G., Witten, D., Hastie, T., and Tibshirani, R. (2023). _An Introduction to Statistical Learning: with Applications in R_. 2nd ed. Springer.
+ Aitchison, J. (1986). _The Statistical Analysis of Compositional Data_. Chapman and Hall, London.
+ Tibshirani, R. (1996). "Regression Shrinkage and Selection via the Lasso." _Journal of the Royal Statistical Society: Series B_, 58(1), 267--288.
+ Statistics Bureau of Japan, MIC (総務省統計局). _Building Starts Survey_ (建築着工統計調査). e-Stat. #link("https://www.e-stat.go.jp/")[https://www.e-stat.go.jp/]
+ Statistics Bureau of Japan, MIC. _Population, Population Dynamics, and Households Based on the Basic Resident Register_ (住民基本台帳に基づく人口、人口動態及び世帯数). e-Stat. #link("https://www.e-stat.go.jp/")[https://www.e-stat.go.jp/]
