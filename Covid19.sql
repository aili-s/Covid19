--import
SELECT * FROM 'CovidDeath.csv' LIMIT 10;
SELECT * FROM 'CovidVactination.csv' LIMIT 10;

-- just look in the data
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM 'CovidDeath.csv' 
WHERE continent is NOT NULL
ORDER BY 1, 2
LIMIT 100;

-- Looking at total_cases vs total_deaths
--Shows likelihood of dying, by country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathOnCases
FROM 'CovidDeath.csv' 
WHERE continent is NOT NULL
AND Location LIKE '%aine%'
ORDER BY 1, 2;

-- Looking at total_cases vs population
-- Showed percentage of population who got the covid (by country)
SELECT Location, date, population, total_cases, (total_cases/population)*100 AS PopulationInfection
FROM 'CovidDeath.csv' 
WHERE continent is NOT NULL AND Location LIKE '%aine%'
ORDER BY 1, 2;

--Country what has the highest infection rate compared to population
SELECT Location, population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population)*100) AS PercentPopulationInfection
FROM 'CovidDeath.csv' 
--WHERE Location LIKE '%aine%'
WHERE continent is NOT NULL
GROUP BY Location, population
ORDER BY PercentPopulationInfection DESC;

--Showing country with highest death count per population
SELECT Location, population, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM 'CovidDeath.csv'
WHERE continent is NOT NULL
GROUP BY Location, population
ORDER BY TotalDeathCount DESC;

--Showing continent with highest death count
SELECT continent,
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM 'CovidDeath.csv'
WHERE continent is NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--all data by continent
SELECT Location,
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM 'CovidDeath.csv'
WHERE continent is NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

--Global numbers per hours
SELECT date, SUM(new_cases) AS TotalCases, -- SUM(MAX(total_cases))=SUM(new_cases) // total_deaths, ((total_deaths/total_cases)*100) AS DeathOnCases
	SUM(cast (new_deaths as int)) AS TotalDeaths,
	TotalDeaths/TotalCases*100 AS DeathPercentage
FROM 'CovidDeath.csv' 
WHERE continent is NOT NULL --AND Location LIKE '%aine%'
GROUP BY date -- total_cases, total_deaths
ORDER BY 1, 2;

--Global numbers
SELECT SUM(new_cases) AS TotalCases, -- SUM(MAX(total_cases))=SUM(new_cases) // total_deaths, ((total_deaths/total_cases)*100) AS DeathOnCases
	SUM(cast (new_deaths as int)) AS TotalDeaths,
	TotalDeaths/TotalCases*100 AS DeathPercentage
FROM 'CovidDeath.csv' 
WHERE continent is NOT NULL --AND Location LIKE '%aine%'
--GROUP BY date -- total_cases, total_deaths
ORDER BY 1, 2;

--			work with 2 table
SELECT * 
FROM 'CovidDeath.csv' AS deat
JOIN 'CovidVactination.csv' AS vact
	ON deat.Location = vact.Location
	AND deat.date = vact.date;

--Looking at vaccination VS population
SELECT deat.continent,
	deat.Location,
	deat.date,
	deat.population,
	vact.new_vaccinations,
	SUM(cast(vact.new_vaccinations as int)) 
	OVER (PARTITION BY deat.Location ORDER BY deat.Location, deat.date)
	AS RollingPeopleVacctination--,
--	(RollingPeopleVacctination/population)*100
	--SUM(CONVERT(int, vact.new_vaccinations)) OVER (PARTITION BY deat.Location)
FROM 'CovidDeath.csv' AS deat
JOIN 'CovidVactination.csv' AS vact
	ON deat.Location = vact.Location
	AND deat.date = vact.date
WHERE deat.continent is NOT NULL
ORDER BY 2, 3;

-- Use CTEs
WITH PopVsVac (continent, Location, date, population, new_vaccinations, RollingPeopleVacctination)
AS
(SELECT deat.continent,
	deat.Location,
	deat.date,
	deat.population,
	vact.new_vaccinations,
	SUM(cast(vact.new_vaccinations as int)) 
	OVER (PARTITION BY deat.Location ORDER BY deat.Location, deat.date)
	AS RollingPeopleVacctination
FROM 'CovidDeath.csv' AS deat
JOIN 'CovidVactination.csv' AS vact
	ON deat.Location = vact.Location
	AND deat.date = vact.date
WHERE deat.continent is NOT NULL
ORDER BY 2, 3)
SELECT *, (RollingPeopleVacctination/population)*100 AS PopulationVsVacctination
FROM PopVsVac;

--Use Temp Table
DROP TABLE if exists PercentPopulationVaccination;
CREATE TEMP TABLE PercentPopulationVaccination
(
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	New_vaccinations numeric,
	RollingPeopleVacctination numeric
);

INSERT INTO PercentPopulationVaccination
SELECT deat.continent,
	deat.Location,
	deat.date,
	deat.population,
	vact.new_vaccinations,
	SUM(cast(vact.new_vaccinations as int)) 
	OVER (PARTITION BY deat.Location ORDER BY deat.Location, deat.date)
	AS RollingPeopleVacctination
FROM 'CovidDeath.csv' AS deat
JOIN 'CovidVactination.csv' AS vact
	ON deat.Location = vact.Location
	AND deat.date = vact.date
WHERE deat.continent is NOT NULL;

SELECT *, (RollingPeopleVacctination/population)*100 AS PopulationVsVacctination
FROM PercentPopulationVaccination;

--Creating view to store data for later visualizations
--DROP VIEW IF EXISTS PercentPopulationVaccination;--need to use different name
CREATE VIEW PercentPopulationVaccinations AS 
SELECT deat.continent,
	deat.Location,
	deat.date,
	deat.population,
	vact.new_vaccinations,
	SUM(cast(vact.new_vaccinations as int)) 
	OVER (PARTITION BY deat.Location ORDER BY deat.Location, deat.date)
	AS RollingPeopleVacctination
FROM 'CovidDeath.csv' AS deat
JOIN 'CovidVactination.csv' AS vact
	ON deat.Location = vact.Location
	AND deat.date = vact.date
WHERE deat.continent is NOT NULL;