/*
=====================================================
STUDENT SUCCESS OPTIMIZATION - SQL ANALYSIS PROJECT
=====================================================

Project: Student Success Optimization
Author: Aaron Diaz
Tools Used: MySQL, Python
Dataset: CleanedBI.csv

Description:
This project analyzes student performance, study behavior,
and demographic trends using SQL.

=====================================================
*/


CREATE DATABASE studentsBI;
USE studentsBI;
CREATE TABLE students (
firstname VARCHAR(100),
lastname VARCHAR(100),
fullname VARCHAR(150),
age INT,
gender VARCHAR(50),
country VARCHAR(100), 
residence VARCHAR(100), 
entryexam FLOAT,
preveducation VARCHAR(100),
studyhours INT,
python FLOAT,
db FLOAT
);

-- =====================================================
-- SECTION 1: DATA EXPLORATION
-- =====================================================

-- How many students are registered in the dataset?

SELECT 
COUNT(*) AS total_students
FROM
students;

-- Which countries are represented?

SELECT 
DISTINCT(country) AS countries
FROM students;

-- What is the average student age?

SELECT 
ROUND(AVG(age)) AS avg_age 
FROM students;

-- What are the average Python and DB scores?

SELECT 
ROUND(AVG(python),2) AS avg_python_score, 
ROUND(AVG(db),2) AS avg_db_score 
FROM students;

-- Which previous education backgrounds are most common?

SELECT 
preveducation, 
COUNT(*) AS Count FROM students
GROUP BY preveducation
ORDER BY count DESC;

-- =====================================================
-- SECTION 2: ACADEMIC PERFORMANCE ANALYSIS
-- =====================================================
-- PERFORMANCE TABLE 
CREATE VIEW perf_base AS
SELECT
    fullname,
    age,
    gender,
    country,
    preveducation,
    studyhours,
    entryexam,
    python,
    db,
    ROUND((python + db)/2,2) AS acad_perf
FROM students;

-- Which students achieved the highest combined technical scores?
SELECT 
fullname, 
acad_perf AS combined_score 
FROM perf_base
ORDER BY combined_score DESC;

-- Which countries have the highest average academic performance?

SELECT 
country,
ROUND(AVG(acad_perf),2) AS avg_academic_performance
FROM perf_base
GROUP BY country
ORDER BY avg_academic_performance DESC;

-- Which education backgrounds produce the strongest results?

SELECT 
preveducation,
ROUND(AVG(entryexam),2) AS avg_entryex_score, 
ROUND(AVG(acad_perf),2) AS avg_academic_perf 
FROM perf_base
GROUP BY preveducation
ORDER BY avg_entryex_score DESC, avg_academic_perf DESC; 

-- Which students achieved above-average overall technical performance?

SELECT 
fullname,
ROUND(acad_perf,2) AS avg_academic_perf 
FROM perf_base
WHERE acad_perf > (SELECT AVG(acad_perf) FROM perf_base)
ORDER BY avg_academic_perf;

-- Which students show inconsistent performance between technical subjects?

SELECT 
fullname,
python AS python_score,
db AS db_score
FROM students
WHERE ABS(python-db) >= 20;


-- =====================================================
-- SECTION 3: STUDY BEHAVIOR ANALYSIS
-- =====================================================

-- Do students with above-average study hours perform better academically?

SELECT 
ROUND(AVG(acad_perf),2) AS acad_perf_studentsuphours
FROM perf_base
WHERE studyhours > (SELECT AVG(studyhours) FROM students);

-- Which students study many hours but still perform poorly?

SELECT 
fullname, 
studyhours, 
acad_perf 
FROM perf_base
WHERE 
studyhours > (SELECT AVG(studyhours) FROM students) 
AND 
acad_perf < (SELECT AVG(acad_perf) FROM perf_base);

-- Which students study fewer hours but achieve excellent results?

SELECT 
fullname,
studyhours,
acad_perf
FROM perf_base
WHERE studyhours < (SELECT AVG(studyhours) FROM students) 
AND 
acad_perf> (SELECT AVG(acad_perf) FROM perf_base);

-- Which countries show the highest study commitment?

SELECT country, AVG(studyhours) FROM students
GROUP BY country
ORDER BY AVG(studyhours) DESC;

-- =====================================================
-- SECTION 4: ADMISSION AND SUCCESS ANALYSIS
-- =====================================================

-- Do high EntryExam scores correlate with strong technical performance?

SELECT fullname, entryexam, acad_perf FROM perf_base
ORDER BY acad_perf DESC;

-- Which students outperformed expectations despite low admission scores?

SELECT 
fullname, 
acad_perf,
entryexam
FROM perf_base
WHERE acad_perf > (SELECT AVG(acad_perf) FROM perf_base)
AND
entryexam < (SELECT AVG(entryexam) FROM students);

-- Which students underperformed despite strong admission results?

SELECT 
fullname,
acad_perf,
entryexam
FROM perf_base
WHERE entryexam > (SELECT AVG(entryexam) FROM students)
AND
acad_perf < (SELECT AVG(acad_perf) FROM perf_base);


-- =====================================================
-- SECTION 5: DEMOGRAPHIC INSIGHTS
-- =====================================================

-- Which gender performs best academically?

SELECT gender,
ROUND(AVG(acad_perf),2)
FROM perf_base
GROUP BY gender
ORDER BY AVG(acad_perf) DESC;

-- Which age groups achieve the strongest technical scores?

SELECT 
age,
ROUND(AVG(acad_perf),2) as acad_perf
FROM perf_base
GROUP BY age
ORDER BY acad_perf DESC;

-- Which demographic groups may require academic support?

SELECT 
country,
ROUND(AVG(acad_perf),2) AS AVG_acad_perf,
CASE
	WHEN AVG(acad_perf) <= (SELECT AVG(acad_perf) FROM perf_base) THEN 'Support Needed'
    ELSE 'Performing Well'
    END AS 'Support Status'
FROM perf_base
GROUP BY country
ORDER BY AVG_acad_perf;

-- Which countries represent the institution’s strongest talent pools?

SELECT 
country,
ROUND(AVG(acad_perf),2) AS avg_acad_perf
FROM perf_base
GROUP BY country
HAVING avg_acad_perf > (SELECT AVG(acad_perf) FROM perf_base)
ORDER BY avg_acad_perf DESC;

-- =====================================================
-- SECTION 6: ADVANCED SQL ANALYSIS
-- =====================================================

-- Rank students based on overall academic performance.

SELECT 
RANK() OVER(ORDER BY acad_perf DESC) AS acad_perf_rank,
fullname,
acad_perf AS overallscore
FROM perf_base;

-- Create performance categories (Excellent, Good, Average, At Risk).

SELECT 
fullname,
acad_perf AS overallscore,
CASE
	WHEN acad_perf >= 90 THEN 'EXCELLENT'
    WHEN acad_perf >= 80 THEN 'GOOD'
    WHEN acad_perf >= (SELECT AVG(acad_perf) FROM perf_base) THEN 'AVERAGE'
    ELSE 'AT RISK'
    END AS 'Performance'
FROM perf_base
ORDER BY acad_perf DESC;

-- Identify the top 10% highest-performing students.
WITH percentrank AS
(
	SELECT 
	fullname,
	age,
	gender,
	country,
	studyhours,
	acad_perf AS overall_perf,
	PERCENT_RANK() OVER(ORDER BY acad_perf DESC) AS perc_rank
    FROM perf_base
)

SELECT 
	fullname,
	age,
	gender,
	country,
	studyhours,
	overall_perf
FROM percentrank
WHERE perc_rank < .10;

-- Compare each student’s performance against the institutional average.

SELECT
fullname,
acad_perf AS overall_perf,
ROUND(AVG(acad_perf) OVER(),2) AS institute_avg
FROM perf_base
ORDER BY acad_perf;

/*
=====================================================
					  INSIGHTS
=====================================================

1. High study hours does not necessarily translate into strong technical performance, 
   suggesting possible inefficiencies in study methods or learning difficulties.
2. Academic performance varies significantly across countries, indicating potential 
   differences in educational preparation or academic background.
3. Admission exam performance alone is not a fully reliable indicator of future academic 
   success.
4. Student performance distribution reveals a concentrated group of high-performing students 
   significantly above the institutional average.
5. Several students show large performance gaps between Python and Database subjects, suggesting 
   uneven technical specialization.
6. Certain demographic groups perform below the institutional academic benchmark and may benefit 
   from targeted academic support initiatives.

*/