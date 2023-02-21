/*
Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/


SELECT *
FROM CovidDeaths$
WHERE continent is not null
ORDER BY 3,4


-- Select Data we are going to be starting with


SELECT 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths, 
	population
FROM CovidDeaths$
WHERE continent is not null
ORDER BY 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country


SELECT 
	location, 
	date, 
	total_cases, 
	total_deaths, 
	(total_deaths/total_cases) * 100 AS DeathPercentage
FROM CovidDeaths$
WHERE location like '%states%' and continent is not null
ORDER BY 1,2



-- Total Cases vs Population
-- Shows what percentage of population infected with Covid


SELECT 
	location, 
	date, 
	population, 
	total_cases, (total_cases/population) * 100 AS PercentagePopulationInfected
FROM CovidDeaths$
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population


SELECT 
	location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population)) * 100 AS PercentagePopulationInfected
FROM CovidDeaths$
GROUP BY location, population
Order BY PercentagePopulationInfected desc


-- Countries with Highest Death Count per Population


SELECT 
	location, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- BY Continent

-- Showing continents with the highest death counts per population


SELECT 
	continent, 
	MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount desc



-- GLOBAL NUMBERS


SELECT 
	SUM(new_cases) as total_cases, 
	SUM(cast(new_deaths as int)) as total_deaths, 
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths$
WHERE continent is not null
ORDER BY 1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine


SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3


-- Using CTE to perform Calculation on Partition By in previous query


WITH PopvsVAC (
			Continent,
			Location, 
			Date,
			Population, 
			New_Vaccinations, 
			RollingPeopleVaccinated
			)
AS 
(
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVAC


-- Using TEMP TABLE to perform Calculation on Partition By in previous query


DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as 
SELECT 
	dea.continent, 
	dea.location, 
	dea.date, 
	dea.population, 
	vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths$ dea
JOIN CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
