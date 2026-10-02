USE job_market_tracker;

/* ============================================================
   DATA ANALYST MARKET INTELLIGENCE
   SQL Analysis & Dashboard Queries
   ============================================================ */

/* ============================================================
   01. DATASET & TABLE SETUP
   ============================================================ */

-- Preview the main job dataset.
SELECT *
FROM data_analyst_jobs;

-- Preview job skills stored in the original tagsAndSkills column.
SELECT
    jobId,
    tagsAndSkills
FROM data_analyst_jobs
LIMIT 5;

-- Ensure salary columns use a numeric data type for analysis.
ALTER TABLE data_analyst_jobs
    MODIFY salary_min_lpa DECIMAL(10,2),
    MODIFY salary_max_lpa DECIMAL(10,2),
    MODIFY salary_mid_lpa DECIMAL(10,2);

-- Create numeric salary columns for SQL analysis.
-- Missing or non-numeric salary values remain NULL.
ALTER TABLE data_analyst_jobs
    ADD COLUMN salary_min_num DECIMAL(10,2),
    ADD COLUMN salary_max_num DECIMAL(10,2),
    ADD COLUMN salary_mid_num DECIMAL(10,2);

-- Populate the numeric salary columns from the existing LPA salary columns.
UPDATE data_analyst_jobs
SET
    salary_min_num =
        CASE
            WHEN TRIM(salary_min_lpa) REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN CAST(TRIM(salary_min_lpa) AS DECIMAL(10,2))
            ELSE NULL
        END,

    salary_max_num =
        CASE
            WHEN TRIM(salary_max_lpa) REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN CAST(TRIM(salary_max_lpa) AS DECIMAL(10,2))
            ELSE NULL
        END,

    salary_mid_num =
        CASE
            WHEN TRIM(salary_mid_lpa) REGEXP '^[0-9]+(\\.[0-9]+)?$'
            THEN CAST(TRIM(salary_mid_lpa) AS DECIMAL(10,2))
            ELSE NULL
        END;

/*
   Create a normalized skill table.
   Each row represents one skill associated with a job posting.
*/
CREATE TABLE job_skills (
    job_id VARCHAR(50),
    skill VARCHAR(100)
);

-- Split the comma-separated tagsAndSkills values into individual skills.
INSERT INTO job_skills (job_id, skill)
SELECT
    j.jobId,
    TRIM(s.skill)
FROM data_analyst_jobs AS j
JOIN JSON_TABLE(
    CONCAT(
        '["',
        REPLACE(j.tagsAndSkills, ',', '","'),
        '"]'
    ),
    '$[*]' COLUMNS (
        skill VARCHAR(100) PATH '$'
    )
) AS s;

-- Preview the normalized skill table.
SELECT *
FROM job_skills
LIMIT 20;


/* ============================================================
   02. MARKET STRUCTURE
   ============================================================ */

-- Total number of Data Analyst job postings.
SELECT
    COUNT(*) AS total_data_analyst_jobs
FROM data_analyst_jobs;

-- Job locations with the highest number of openings.
SELECT
    location,
    COUNT(*) AS job_count
FROM data_analyst_jobs
GROUP BY location
ORDER BY job_count DESC;

-- Companies with the highest number of Data Analyst openings.
SELECT
    companyName,
    COUNT(*) AS job_count
FROM data_analyst_jobs
GROUP BY companyName
ORDER BY job_count DESC
LIMIT 15;

-- Distribution of job postings across experience levels.
SELECT
    CASE
        WHEN minimumExperience BETWEEN 0 AND 2 THEN 'Early Career'
        WHEN minimumExperience BETWEEN 3 AND 5 THEN 'Mid Career'
        WHEN minimumExperience BETWEEN 6 AND 10 THEN 'Experienced'
        WHEN minimumExperience >= 11 THEN 'Senior'
        ELSE 'Not Specified'
    END AS experience_level,
    COUNT(*) AS job_count
FROM data_analyst_jobs
GROUP BY experience_level
ORDER BY job_count DESC;

-- Proportion of job postings that disclose salary information.
SELECT
    CASE
        WHEN salary = 'Not disclosed' THEN 'Not Disclosed'
        ELSE 'Disclosed'
    END AS salary_info,
    COUNT(*) AS job_count
FROM data_analyst_jobs
GROUP BY salary_info;


/* ============================================================
   03. SKILLS INTELLIGENCE
   ============================================================ */

-- Most frequently demanded skills across Data Analyst job postings.
SELECT
    LOWER(TRIM(skill)) AS skill,
    COUNT(DISTINCT job_id) AS job_count
FROM job_skills
GROUP BY LOWER(TRIM(skill))
ORDER BY job_count DESC
LIMIT 20;

-- Demand for major Data Analyst tools.
SELECT
    LOWER(TRIM(skill)) AS skill,
    COUNT(DISTINCT job_id) AS job_count
FROM job_skills
WHERE LOWER(TRIM(skill)) IN
    ('sql', 'python', 'power bi', 'tableau', 'excel', 'r', 'sas')
GROUP BY LOWER(TRIM(skill))
ORDER BY job_count DESC;

-- Number of job postings requiring both SQL and Python.
SELECT
    COUNT(DISTINCT job_id) AS job_count
FROM job_skills
WHERE LOWER(TRIM(skill)) = 'sql'
  AND job_id IN (
      SELECT job_id
      FROM job_skills
      WHERE LOWER(TRIM(skill)) = 'python'
  );

-- Number of job postings requiring both SQL and Power BI.
SELECT
    COUNT(DISTINCT job_id) AS job_count
FROM job_skills
WHERE LOWER(TRIM(skill)) = 'sql'
  AND job_id IN (
      SELECT job_id
      FROM job_skills
      WHERE LOWER(TRIM(skill)) = 'power bi'
  );

-- SQL demand across experience levels.
SELECT
    CASE
        WHEN j.minimumExperience BETWEEN 0 AND 2 THEN 'Early Career'
        WHEN j.minimumExperience BETWEEN 3 AND 5 THEN 'Mid Career'
        WHEN j.minimumExperience BETWEEN 6 AND 10 THEN 'Experienced'
        WHEN j.minimumExperience >= 11 THEN 'Senior'
        ELSE 'Not Specified'
    END AS experience_level,
    COUNT(DISTINCT js.job_id) AS job_count
FROM data_analyst_jobs AS j
JOIN job_skills AS js
    ON j.jobId = js.job_id
WHERE LOWER(TRIM(js.skill)) = 'sql'
GROUP BY experience_level
ORDER BY job_count DESC;

-- Python demand across experience levels.
SELECT
    CASE
        WHEN j.minimumExperience BETWEEN 0 AND 2 THEN 'Early Career'
        WHEN j.minimumExperience BETWEEN 3 AND 5 THEN 'Mid Career'
        WHEN j.minimumExperience BETWEEN 6 AND 10 THEN 'Experienced'
        WHEN j.minimumExperience >= 11 THEN 'Senior'
        ELSE 'Not Specified'
    END AS experience_level,
    COUNT(DISTINCT js.job_id) AS job_count
FROM data_analyst_jobs AS j
JOIN job_skills AS js
    ON j.jobId = js.job_id
WHERE LOWER(TRIM(js.skill)) = 'python'
GROUP BY experience_level
ORDER BY job_count DESC;

-- Most common skills among Early Career Data Analyst jobs.
SELECT
    LOWER(TRIM(js.skill)) AS skill,
    COUNT(DISTINCT js.job_id) AS job_count
FROM data_analyst_jobs AS j
JOIN job_skills AS js
    ON j.jobId = js.job_id
WHERE j.minimumExperience BETWEEN 0 AND 2
GROUP BY LOWER(TRIM(js.skill))
ORDER BY job_count DESC
LIMIT 15;

-- Most frequent skill combinations across job postings.
SELECT
    LOWER(TRIM(a.skill)) AS skill_1,
    LOWER(TRIM(b.skill)) AS skill_2,
    COUNT(DISTINCT a.job_id) AS job_count
FROM job_skills AS a
JOIN job_skills AS b
    ON a.job_id = b.job_id
    AND LOWER(TRIM(a.skill)) < LOWER(TRIM(b.skill))
GROUP BY skill_1, skill_2
ORDER BY job_count DESC
LIMIT 15;

-- Compare major Data Analyst tools across experience levels.
SELECT
    CASE
        WHEN j.minimumExperience BETWEEN 0 AND 2 THEN 'Early Career'
        WHEN j.minimumExperience BETWEEN 3 AND 5 THEN 'Mid Career'
        WHEN j.minimumExperience BETWEEN 6 AND 10 THEN 'Experienced'
        WHEN j.minimumExperience >= 11 THEN 'Senior'
        ELSE 'Not Specified'
    END AS experience_level,

    COUNT(DISTINCT CASE
        WHEN LOWER(TRIM(js.skill)) = 'sql' THEN js.job_id
    END) AS sql_jobs,

    COUNT(DISTINCT CASE
        WHEN LOWER(TRIM(js.skill)) = 'python' THEN js.job_id
    END) AS python_jobs,

    COUNT(DISTINCT CASE
        WHEN LOWER(TRIM(js.skill)) = 'power bi' THEN js.job_id
    END) AS power_bi_jobs,

    COUNT(DISTINCT CASE
        WHEN LOWER(TRIM(js.skill)) = 'tableau' THEN js.job_id
    END) AS tableau_jobs,

    COUNT(DISTINCT CASE
        WHEN LOWER(TRIM(js.skill)) = 'excel' THEN js.job_id
    END) AS excel_jobs

FROM data_analyst_jobs AS j
JOIN job_skills AS js
    ON j.jobId = js.job_id

GROUP BY experience_level
ORDER BY
    CASE experience_level
        WHEN 'Early Career' THEN 1
        WHEN 'Mid Career' THEN 2
        WHEN 'Experienced' THEN 3
        WHEN 'Senior' THEN 4
        ELSE 5
    END;


/* ============================================================
   04. SALARY & CAREER
   ============================================================ */

-- Salary range and average among job postings with disclosed salary.
SELECT
    MIN(salary_mid_num) AS minimum_salary,
    MAX(salary_mid_num) AS maximum_salary,
    AVG(salary_mid_num) AS average_salary
FROM data_analyst_jobs
WHERE salary_mid_num IS NOT NULL
  AND salary_mid_num > 0;

-- Compare average disclosed salary across experience levels.
SELECT
    CASE
        WHEN minimumExperience BETWEEN 0 AND 2 THEN 'Early Career'
        WHEN minimumExperience BETWEEN 3 AND 5 THEN 'Mid Career'
        WHEN minimumExperience BETWEEN 6 AND 10 THEN 'Experienced'
        WHEN minimumExperience >= 11 THEN 'Senior'
        ELSE 'Not Specified'
    END AS experience_level,
    COUNT(*) AS job_count,
    AVG(salary_mid_num) AS average_salary
FROM data_analyst_jobs
WHERE salary_mid_num IS NOT NULL
  AND salary_mid_num > 0
GROUP BY experience_level
ORDER BY
    CASE experience_level
        WHEN 'Early Career' THEN 1
        WHEN 'Mid Career' THEN 2
        WHEN 'Experienced' THEN 3
        WHEN 'Senior' THEN 4
        ELSE 5
    END;

-- Average disclosed salary by location for locations with at least two jobs.
SELECT
    location,
    COUNT(*) AS job_count,
    AVG(salary_mid_num) AS average_salary
FROM data_analyst_jobs
WHERE salary_mid_num IS NOT NULL
  AND salary_mid_num > 0
GROUP BY location
HAVING COUNT(*) >= 2
ORDER BY average_salary DESC;

-- Distribution of disclosed salaries across salary bands.
SELECT
    CASE
        WHEN salary_mid_num < 5 THEN 'Below 5 LPA'
        WHEN salary_mid_num < 10 THEN '5–10 LPA'
        WHEN salary_mid_num < 15 THEN '10–15 LPA'
        WHEN salary_mid_num < 20 THEN '15–20 LPA'
        ELSE '20+ LPA'
    END AS salary_band,
    COUNT(*) AS job_count
FROM data_analyst_jobs
WHERE salary_mid_num IS NOT NULL
  AND salary_mid_num > 0
GROUP BY salary_band
ORDER BY
    CASE salary_band
        WHEN 'Below 5 LPA' THEN 1
        WHEN '5–10 LPA' THEN 2
        WHEN '10–15 LPA' THEN 3
        WHEN '15–20 LPA' THEN 4
        WHEN '20+ LPA' THEN 5
    END;

-- Review the distinct raw location values for data-quality inspection.
SELECT DISTINCT
    location
FROM data_analyst_jobs;


/* ============================================================
   END OF ANALYSIS QUERIES
   ============================================================ */