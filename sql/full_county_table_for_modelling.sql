--Source: https://www.ahrq.gov/data/innovations/clh-data.html

CREATE OR REPLACE TABLE county_base AS
SELECT *
FROM read_csv_auto(
    'C:\Users\enaho\Downloads\county_base_data.csv',
    delim = ',',
    header = true,
    ignore_errors = true
);

PRAGMA table_info(county_base);

CREATE OR REPLACE TABLE county_base_clean AS
SELECT
    LPAD(COUNTYFIPS, 5, '0') AS fips,
    COUNTY AS county,
    STATE AS state,

    -- Population / geography
    ACS_TOT_POP_WT AS population,
    CEN_POPDENSITY_COUNTY AS pop_density,
    AHRF_USDA_RUCC_2023 AS rural_urban_code,

    -- Structural need
    SAIPE_PCT_POV AS poverty_rate,
    ACS_MEDIAN_HH_INC AS median_income,
    AHRF_UNEMPLOYED_RATE AS unemployment_rate,
    ACS_PCT_UNINSURED AS uninsured_rate,
    ACS_PCT_MEDICAID_ANY AS medicaid_rate,

    -- Better provider supply / access infrastructure
    CCBP_PHYS_RATE AS physician_office_rate,
    AHRF_NURSE_PRACT_RATE AS nurse_practitioner_rate,
    AHRF_PHYSICIAN_ASSIST_RATE AS physician_assistant_rate,
    POS_FQHC_RATE AS fqhc_rate,
    POS_RHC_RATE AS rhc_rate,

    -- Distance/access
    POS_MEAN_DIST_CLINIC AS dist_clinic,
    POS_MEAN_DIST_ED AS dist_ed,

    -- Keep NHSC, but treat as intervention/support, not general provider supply
    AHRF_NHSC_FTE_PROV_RATE AS nhsc_provider_rate

FROM county_base
WHERE COUNTYFIPS IS NOT NULL
  AND TERRITORY = 0
  AND STATE NOT IN ('Alaska', 'Hawaii');

CREATE OR REPLACE TABLE access_model_base AS
SELECT
    c.*,
    COALESCE(h.hpsa_score, 0) AS hpsa_score,
    CASE WHEN h.fips IS NOT NULL THEN 1 ELSE 0 END AS is_hpsa
FROM county_base_clean c
LEFT JOIN hpsa_final h
    ON c.fips = h.fips;


CREATE OR REPLACE TABLE access_model_ready AS
SELECT
    fips,
    state,
    county,

    population,
    pop_density,
    rural_urban_code,

    poverty_rate,
    median_income,
    unemployment_rate,
    uninsured_rate,
    medicaid_rate,

    COALESCE(physician_office_rate, 0) AS physician_office_rate_clean,
    COALESCE(nurse_practitioner_rate, 0) AS nurse_practitioner_rate_clean,
    COALESCE(physician_assistant_rate, 0) AS physician_assistant_rate_clean,
    COALESCE(fqhc_rate, 0) AS fqhc_rate_clean,
    COALESCE(rhc_rate, 0) AS rhc_rate_clean,

    COALESCE(dist_clinic, 0) AS dist_clinic_clean,
    COALESCE(dist_ed, 0) AS dist_ed_clean,

    COALESCE(nhsc_provider_rate, 0) AS nhsc_provider_rate_clean,

    hpsa_score,
    is_hpsa
FROM access_model_base
WHERE population IS NOT NULL
  AND poverty_rate IS NOT NULL
  AND uninsured_rate IS NOT NULL
  AND unemployment_rate IS NOT NULL
  AND pop_density IS NOT NULL;
    


COPY access_model_ready
TO 'C:\Users\enaho\Downloads\access_model.csv'
WITH (HEADER, DELIMITER ',');
