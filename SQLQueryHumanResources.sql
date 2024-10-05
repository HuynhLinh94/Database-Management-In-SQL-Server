CREATE DATABASE HumanResources;

USE HumanResources;

SELECT * FROM [dbo].[Human Resources];

EXEC sp_rename '[dbo].[Human Resources].[id]', emp_id, 'COLUMN';
ALTER TABLE [dbo].[Human Resources] ALTER COLUMN [emp_id] VARCHAR(20) NOT NULL;
SELECT [emp_id] FROM [dbo].[Human Resources];

SELECT [termdate] FROM [dbo].[Human Resources];

UPDATE [dbo].[Human Resources]
SET [termdate] = CAST(SUBSTRING([termdate], 1, 10) AS DATE)
WHERE [termdate] LIKE '% UTC'; 
--SUBSTRING(OrderDate, 1, 10): Lấy 10 ký tự đầu tiên từ chuỗi OrderDate, tức là phần ngày ("YYYY-MM-DD").
--CAST(... AS DATE): Chuyển đổi chuỗi ngày này sang kiểu DATE.
--WHERE OrderDate LIKE '% UTC': Chỉ cập nhật các bản ghi mà có chứa " UTC" ở cuối chuỗi.

ALTER TABLE [dbo].[Human Resources] ALTER COLUMN [termdate] DATE;

ALTER TABLE [dbo].[Human Resources] ADD age INT;

UPDATE [dbo].[Human Resources]
SET age = DATEDIFF(YEAR,[birthdate] , GETDATE()) - 
           CASE 
               WHEN MONTH([birthdate]) > MONTH(GETDATE()) OR 
                    (MONTH([birthdate]) = MONTH(GETDATE()) AND DAY([birthdate]) > DAY(GETDATE())) 
               THEN 1 
               ELSE 0 
           END;
SELECT [birthdate],[age] FROM [dbo].[Human Resources];

SELECT min([age]) as youngest, max([age]) as oldest
FROM [dbo].[Human Resources];

SELECT COUNT(*) FROM [dbo].[Human Resources] WHERE age<18;

--1. What is the gender breakdown of employees in the company?
SELECT [gender], count(*) as [count]
FROM [Human Resources]
WHERE age >= 18 and termdate is null
GROUP BY gender;

--2. What is the race/ethnicity breakdown of employees in the company?
SELECT [race], count(*) as [count]
FROM [Human Resources]
WHERE age >= 18 and termdate is null
GROUP BY race
ORDER BY count DESC;

--3. What is the age distribution of employees in the company?
SELECT min([age]) as youngest, max([age]) as oldest
FROM [dbo].[Human Resources]
WHERE age >= 18 and termdate is null;

SELECT 
    CASE
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65 and above'
    END AS [age_group], gender,
    COUNT(*) AS [count]
FROM [dbo].[Human Resources]
WHERE age >= 18 AND termdate IS NULL
GROUP BY 
    CASE
        WHEN age >= 18 AND age <= 24 THEN '18-24'
        WHEN age >= 25 AND age <= 34 THEN '25-34'
        WHEN age >= 35 AND age <= 44 THEN '35-44'
        WHEN age >= 45 AND age <= 54 THEN '45-54'
        WHEN age >= 55 AND age <= 64 THEN '55-64'
        ELSE '65 and above'
    END, gender
ORDER BY age_group, gender;

--4. How many employees work at headquarters versus remote locations?
SELECT [location],COUNT(*) AS [count]
FROM [Human Resources]
WHERE age >= 18 AND termdate IS NULL
GROUP BY [location];

--5. What is the average lenght of employeement for employees who have been terminated?
SELECT ROUND(AVG(DATEDIFF(DAY,hire_date,termdate) / 365), 0) AS avg_length_employment
FROM [Human Resources]
WHERE termdate IS NOT NULL AND termdate <= GETDATE() AND age >= 18;

--6.How does the gender distribution vary across departments and job titles?
SELECT department, gender,COUNT(*) AS [count]
FROM [Human Resources]
WHERE age >= 18 AND termdate IS NULL
GROUP BY department, gender
ORDER BY department;

--7.What is the distribution of job titles across the company?
SELECT jobtitle,COUNT(*) AS [count]
FROM [Human Resources]
WHERE age >= 18 AND termdate IS NULL
GROUP BY jobtitle
ORDER BY jobtitle DESC;

--8.Which department has the highest turnover rate?
SELECT department, total_count, terminated_count, 
	ROUND(CASE 
            WHEN total_count = 0 THEN 0  
            ELSE terminated_count / CAST(total_count AS FLOAT)
          END, 2) AS terminated_rate
FROM ( SELECT department, COUNT(*) AS total_count,
			  SUM(CASE WHEN termdate IS NOT NULL AND termdate <= GETDATE() THEN 1 ELSE 0 END) AS terminated_count
	   FROM [dbo].[Human Resources]
	   WHERE age >=18
	   GROUP BY department
	   ) AS temp
ORDER BY terminated_rate DESC;

--9. What is the distribution of employees across location by city and state?
SELECT location_state,COUNT(*) AS [count]
FROM [Human Resources]
WHERE age >= 18 AND termdate IS NULL
GROUP BY location_state
ORDER BY count DESC;

--10. How has the company's employees count changed over time based on hire and term dates?
SELECT year, hires, terminations, (hires-terminations) AS net_change,
	   ROUND(CASE 
            WHEN hires = 0 THEN 0  
            ELSE (hires - terminations) / CAST(hires AS FLOAT) * 100 
          END, 2) AS net_change_percent
FROM ( SELECT YEAR([hire_date]) AS year, COUNT(*) AS hires,
			SUM(CASE WHEN termdate IS NOT NULL AND termdate <= GETDATE() THEN 1 ELSE 0 END) AS terminations
	   FROM [dbo].[Human Resources]
	   WHERE age >=18 
	   GROUP BY YEAR([hire_date])
	   ) AS temp
ORDER BY year ASC;

--11. Which is the tenure distribution for each department?
SELECT department, ROUND(AVG(DATEDIFF(DAY,[hire_date],[termdate])/365),0) AS avg_tenure
FROM [dbo].[Human Resources]
WHERE termdate <= GETDATE() AND termdate IS NOT NULL AND age >= 18 
GROUP BY department;