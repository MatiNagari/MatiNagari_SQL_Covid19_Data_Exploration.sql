/*
=============================================================================================
COVID-19 DATA EXPLORATION
Author   : Mati Nagari
Database : PortfolioProj
Dataset  : Our World in Data (Global COVID-19 Dataset)
=============================================================================================

EXECUTIVE SUMMARY: 
Conducted a global analysis of COVID-19 impact, focusing on the correlation between 
infection rates and vaccination rollouts. Developed a multi-stage reporting layer 
that tracks rolling vaccination totals and mortality percentages by continent.

BUSINESS PROBLEM: 
Global health data is often fragmented. This project provides a unified view of pandemic 
progression to help stakeholders understand the efficacy of vaccination rollouts and 
identify high-mortality risk zones.

RECOMMENDATIONS: 
1. Use rolling vaccination totals to predict when a region hits stability thresholds.
2. Cross-reference death rates with GDP (Next Phase) to analyze healthcare equity.
3. Prioritize "First-Dose Penetration" as a primary KPI for resource-strained regions.

SKILLS DEMONSTRATED:
    - Joins
    - CTEs (Common Table Expressions)
    - Temp Tables
    - Window Functions
    - Aggregate Functions
    - Creating Views
    - Converting Data Types
    - NULLIF for safe division
=============================================================================================
*/


-- =============================================================
-- 1. PREVIEW THE RAW DATA (Selected Columns Only)
-- =============================================================

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProj..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1, 2;

SELECT location, date, new_vaccinations, total_vaccinations, people_vaccinated
FROM PortfolioProj..CovidVaccinations$
WHERE continent IS NOT NULL
ORDER BY 1, 2;


-- =============================================================
-- 2. TOTAL CASES VS TOTAL DEATHS (United States)
--    Shows the likelihood of dying if you contracted Covid in the US
-- =============================================================

SELECT
    location,
    date,
    total_cases,
    total_deaths,
    (CAST(total_deaths AS FLOAT) / NULLIF(total_cases, 0)) * 100 AS DeathPercentage
FROM PortfolioProj..CovidDeaths$
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY 1, 2;


-- =============================================================
-- 3. TOTAL CASES VS POPULATION (United States)
--    Shows what percentage of the US population contracted Covid
-- =============================================================

SELECT
    location,
    date,
    population,
    total_cases,
    (CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProj..CovidDeaths$
WHERE location LIKE '%states%'
  AND continent IS NOT NULL
ORDER BY 1, 2;


-- =============================================================
-- 4. COUNTRIES WITH HIGHEST INFECTION RATE RELATIVE TO POPULATION
-- =============================================================

SELECT
    location,
    population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX(CAST(total_cases AS FLOAT) / NULLIF(population, 0)) * 100 AS PercentPopulationInfected
FROM PortfolioProj..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;


-- =============================================================
-- 5. COUNTRIES WITH HIGHEST TOTAL DEATH COUNT
-- =============================================================

SELECT
    location,
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProj..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- =============================================================
-- 6. CONTINENTS WITH HIGHEST TOTAL DEATH COUNT
-- =============================================================

SELECT
    continent,
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProj..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- =============================================================
-- 7. GLOBAL NUMBERS (Overall Totals)
-- =============================================================

SELECT
    SUM(new_cases)                                                      AS TotalCases,
    SUM(CAST(new_deaths AS INT))                                        AS TotalDeaths,
    SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100     AS GlobalDeathPercentage
FROM PortfolioProj..CovidDeaths$
WHERE continent IS NOT NULL;


-- =============================================================
-- 8. GLOBAL NUMBERS BY DATE (Daily Breakdown)
-- =============================================================

SELECT
    date,
    SUM(new_cases)                                                      AS TotalCases,
    SUM(CAST(new_deaths AS INT))                                        AS TotalDeaths,
    SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100     AS DailyDeathPercentage
FROM PortfolioProj..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1;


-- =============================================================
-- 9. POPULATION VS VACCINATIONS — USING CTE
--    Rolling count of vaccinated people per country over time
-- =============================================================

WITH PopvsVac AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT))
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProj.dbo.CovidDeaths$ dea
    JOIN PortfolioProj.dbo.CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date    = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT
    *,
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(population, 0)) * 100 AS RollingVaccinationPct
FROM PopvsVac
ORDER BY location, date;


-- =============================================================
-- 10. POPULATION VS VACCINATIONS — USING TEMP TABLE
--     Same logic as CTE above; useful for re-use within the session
-- =============================================================

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
    Continent               NVARCHAR(255),
    Location                NVARCHAR(255),
    Date                    DATETIME,
    Population              NUMERIC,
    New_Vaccinations        NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

INSERT INTO #PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT))
        OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProj.dbo.CovidDeaths$ dea
JOIN PortfolioProj.dbo.CovidVaccinations$ vac
    ON dea.location = vac.location
    AND dea.date    = vac.date
WHERE dea.continent IS NOT NULL;

SELECT
    *,
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(Population, 0)) * 100 AS RollingVaccinationPct
FROM #PercentPopulationVaccinated
ORDER BY Location, Date;


-- =============================================================
-- 11. CREATE VIEW — For later visualizations in Tableau / Power BI
--     Stores rolling vaccination data including vaccination rate %
-- =============================================================

CREATE OR ALTER VIEW PercentPopulationVaccinated AS
WITH BaseVaccination AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT))
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
    FROM PortfolioProj.dbo.CovidDeaths$ dea
    JOIN PortfolioProj.dbo.CovidVaccinations$ vac
        ON dea.location = vac.location
        AND dea.date    = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT
    continent,
    location,
    date,
    population,
    new_vaccinations,
    RollingPeopleVaccinated,
    (CAST(RollingPeopleVaccinated AS FLOAT) / NULLIF(population, 0)) * 100 AS RollingVaccinationPct
FROM BaseVaccination;
