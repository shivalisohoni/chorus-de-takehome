/********************************************************************
 Q1. Retrieve all active patients
 -------------------------------------------------------------------
 Goal:
   Identify all patients marked as active in the "Patient" table.
   
 ********************************************************************/

--Tested multiple Boolean notations in PostgreSQL to confirm equivalence.

-- Option 1: Test using literal TRUE keyword
SELECT * FROM "Patient" WHERE "active" = TRUE;

-- Option 2: Test using implicit truth check (short form)
SELECT * FROM "Patient" WHERE "active";

-- Option 3: Test using character 't' (Postgres internal representation)
SELECT * FROM "Patient" WHERE "active" = 't';

-- Option 4: Test using 'IS TRUE' syntax (ANSI SQL form)
SELECT * FROM "Patient" WHERE "active" IS TRUE;


/********************************************************************
 Q2. Find encounters for a specific patient
 -------------------------------------------------------------------
 Goal:
   Given a patient_id, retrieve all encounters for that patient
   including status, date, and reason.
 ********************************************************************/
-- Static Example
-- Step 1: Get a valid patient_id (UUID)
SELECT "id", "name" FROM "Patient" LIMIT 5;
-- Example result:
-- 1fdf0010-7b22-4562-9765-07e70de18fdd | Kimberly Howard

-- Step 2: Query all encounters for that patient
SELECT e."id",
       e."status",
       e."encounter_date"
FROM "Encounter" e
WHERE e."patient_id" = '1fdf0010-7b22-4562-9765-07e70de18fdd';

-- Dynamic Example
-- Retrieve encounters dynamically for any patient
-- Uses a parameterized variable for reusability in psql.

-- Step 1: Set the variable in psql:
\set patient_uuid '1fdf0010-7b22-4562-9765-07e70de18fdd'

--Step 2: Run the query using the variable:

SELECT e."id",
       e."status",
       e."encounter_date"
FROM "Encounter" e
WHERE e."patient_id" = :'patient_uuid';


/********************************************************************
 Q3. List all observations recorded for a patient
 -------------------------------------------------------------------
 Goal:
   For a given patient_id (UUID), return all recorded observations,
   including observation type, value, unit, and recorded date.
 ********************************************************************/

-- Step 1: Get a valid patient_id (UUID)
SELECT "id", "name"
FROM "Patient"
LIMIT 5;
-- Example result:
-- 5c625e05-7dad-476d-9ee4-e59f6940c19a | Ann Knox


/************************************************************
 Static Example:
   Use a specific UUID directly to view all observations for
   one patient.
 ************************************************************/
SELECT o."patient_id",
       o."type",
       o."value",
       o."unit",
       o."recorded_at"
FROM "Observation" o
WHERE o."patient_id" = '5c625e05-7dad-476d-9ee4-e59f6940c19a'
ORDER BY o."recorded_at" DESC;

/************************************************************
 Dynamic Example:
   Use a psql variable for the patient UUID to make the query
   reusable for multiple patients without editing SQL text.
 ************************************************************/

-- Step 1: Set the variable in psql:
\set patient_uuid '5c625e05-7dad-476d-9ee4-e59f6940c19a'

-- Step 2: Run the query using the variable:
SELECT o."patient_id",
       o."type",
       o."value",
       o."unit",
       o."recorded_at"
FROM "Observation" o
WHERE o."patient_id" = :'patient_uuid'
ORDER BY o."recorded_at" DESC;


/********************************************************************
 Q4. Find the most recent encounter for each patient
 -------------------------------------------------------------------
 Goal:
   Retrieve each patient’s most recent encounter (latest encounter_date),
   returning the patient_id, encounter_date, and status.
 ********************************************************************/

SELECT ranked."patient_id",
       ranked."encounter_date",
       ranked."status"
FROM (
    SELECT e.*,
           ROW_NUMBER() OVER (
               PARTITION BY e."patient_id"
               ORDER BY e."encounter_date" DESC
           ) AS rn
    FROM "Encounter" e
) ranked
WHERE ranked.rn = 1;


/********************************************************************
 Q5. Find patients who have had encounters with more than one practitioner
 -------------------------------------------------------------------
 Goal:
   Identify patients who have seen more than one distinct practitioner
   based on the "Encounter" table.
 ********************************************************************/

SELECT e."patient_id",
       COUNT(DISTINCT e."practitioner_id") AS distinct_practitioners
FROM "Encounter" e
WHERE e."practitioner_id" IS NOT NULL
GROUP BY e."patient_id"
HAVING COUNT(DISTINCT e."practitioner_id") > 1
ORDER BY distinct_practitioners DESC;


/********************************************************************
 Q6. Find the top 3 most prescribed medications
 -------------------------------------------------------------------
 Goal:
   Identify the three most commonly prescribed medications from the
   "MedicationRequest" table.
   Demonstrates both:
     1. Standard aggregation + LIMIT
     2. Window function (RANK)
 ********************************************************************/

-- Approach 1: Aggregation + LIMIT
 ------------------------------------------------------------
 -- Groups by medication_name and counts total prescriptions.
 -- Orders descending by count.
 -- Limits to top 3 results.

SELECT mr."medication_name",
       COUNT(*) AS prescription_count
FROM "MedicationRequest" mr
GROUP BY mr."medication_name"
ORDER BY prescription_count DESC
LIMIT 3;


 -- Approach 2: Window Function (RANK)
 ------------------------------------------------------------
 -- Uses RANK() OVER(ORDER BY COUNT(*) DESC) to compute rank of each medication based on prescription frequency.
 -- Makes it easy to extend beyond top 3 or handle ties.

SELECT ranked."medication_name",
       ranked.prescription_count
FROM (
    SELECT mr."medication_name",
           COUNT(*) AS prescription_count,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rank
    FROM "MedicationRequest" mr
    GROUP BY mr."medication_name"
) ranked
WHERE ranked.rank <= 3
ORDER BY ranked.rank;


/********************************************************************
 Q7. Find practitioners who have never prescribed any medication
 -------------------------------------------------------------------
 Goal:
   Identify all practitioners from the "Practitioner" table who do not
   appear in the "MedicationRequest" table as a prescribing practitioner.
 ********************************************************************/

SELECT p."id",
       p."name",
       p."specialty"
FROM "Practitioner" p
LEFT JOIN "MedicationRequest" mr
       ON p."id" = mr."practitioner_id"
WHERE mr."id" IS NULL
ORDER BY p."name";


/********************************************************************
 Q8. Find the average number of encounters per patient
 -------------------------------------------------------------------
 Goal:
   Calculate the average number of encounters per patient,
   rounded to two decimal places.
 ********************************************************************/

SELECT ROUND(AVG(encounter_count)::numeric, 2) AS avg_encounters_per_patient
FROM (
    SELECT e."patient_id",
           COUNT(*) AS encounter_count
    FROM "Encounter" e
    GROUP BY e."patient_id"
) patient_counts;


/********************************************************************
 Q9. Identify patients who have never had an encounter
     but have a medication request
 -------------------------------------------------------------------
 Goal:
   Find all patients who appear in the "MedicationRequest" table
   but have no corresponding record in the "Encounter" table.
 ********************************************************************/

SELECT DISTINCT mr."patient_id",
       p."name",
       p."active"
FROM "MedicationRequest" mr
JOIN "Patient" p
  ON mr."patient_id" = p."id"
LEFT JOIN "Encounter" e
  ON p."id" = e."patient_id"
WHERE e."id" IS NULL
ORDER BY p."name";


/********************************************************************
 Q10. Determine patient retention by cohort
 -------------------------------------------------------------------
 Goal:
   For each cohort (based on the month of a patient's first encounter),
   count how many patients had at least one encounter in the
   following six months.
 ********************************************************************/

WITH first_encounter AS (
    SELECT "patient_id",
           DATE_TRUNC('month', MIN("encounter_date")) AS first_month
    FROM "Encounter"
    GROUP BY "patient_id"
),
encounters_within_6mo AS (
    SELECT f."patient_id",
           f."first_month",
           e."encounter_date"
    FROM first_encounter f
    JOIN "Encounter" e
      ON f."patient_id" = e."patient_id"
     AND e."encounter_date" >= f."first_month"
     AND e."encounter_date" < (f."first_month" + INTERVAL '6 month')
)
SELECT TO_CHAR(f."first_month", 'YYYY-MM') AS cohort_month,
       COUNT(DISTINCT f."patient_id") AS cohort_size,
       COUNT(DISTINCT e."patient_id") AS retained_patients,
       ROUND(
         (COUNT(DISTINCT e."patient_id")::numeric /
          COUNT(DISTINCT f."patient_id")) * 100, 2
       ) AS retention_rate_pct
FROM first_encounter f
LEFT JOIN encounters_within_6mo e
  ON f."patient_id" = e."patient_id"
GROUP BY f."first_month"
ORDER BY f."first_month";