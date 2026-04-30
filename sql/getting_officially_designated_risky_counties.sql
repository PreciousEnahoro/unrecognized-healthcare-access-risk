--Source: https://data.hrsa.gov/data/download?titleFilter=Shortage+Areas


-- STEP 1: Load CSV 
CREATE OR REPLACE TABLE hpsa_raw AS
SELECT *
FROM read_csv_auto(
    'C:\Users\enaho\Downloads\hpsa_raw.csv',
    delim = ',',
    header = true,
    ignore_errors = true
);

-- STEP 2: Clean quotes + correct fields
CREATE OR REPLACE TABLE hpsa_cleaned AS
SELECT
    TRIM(BOTH '"' FROM "HPSA Discipline Class") AS discipline,
    TRIM(BOTH '"' FROM "Designation Type") AS designation_type,
    TRIM(BOTH '"' FROM "HPSA Status") AS status,

    -- Correct geographic fields
    TRIM(BOTH '"' FROM "State FIPS Code") AS fips,
    TRIM(BOTH '"' FROM "Common County Name") AS county,
    TRIM(BOTH '"' FROM "Primary State Abbreviation") AS state,

    CAST(TRIM(BOTH '"' FROM "HPSA Score") AS DOUBLE) AS hpsa_score
FROM hpsa_raw;

-- STEP 3: Filter
CREATE OR REPLACE TABLE hpsa_filtered AS
SELECT *
FROM hpsa_cleaned
WHERE 
    discipline = 'Primary Care'
    AND designation_type = 'Geographic HPSA'
    AND status = 'Designated';

-- STEP 4: Collapse to county level
CREATE OR REPLACE TABLE hpsa_county AS
SELECT
    fips,
    MAX(county) AS county,
    MAX(state) AS state,
    MAX(hpsa_score) AS hpsa_score
FROM hpsa_filtered
WHERE fips IS NOT NULL
GROUP BY fips;

-- STEP 5: Final dataset
CREATE OR REPLACE TABLE hpsa_final AS
SELECT
    *,
    CASE 
        WHEN hpsa_score >= 14 THEN 1 
        ELSE 0 
    END AS high_shortage
FROM hpsa_county;



