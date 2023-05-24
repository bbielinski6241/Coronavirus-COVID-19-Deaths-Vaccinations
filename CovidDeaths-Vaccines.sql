SELECT *
FROM PortfolioProjectX.dbo.CovidDeathsX
ORDER BY 3,4;

-- Select Initial Data

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProjectX.dbo.CovidDeathsX
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths (Likilihood of Dying When Covid is Contracted in a Specific Country)


SELECT Location, date, total_cases, total_deaths, total_deaths/total_cases * 100 AS DeathPercentage
FROM PortfolioProjectX.dbo.CovidDeathsX

-- Likelihood of Dying if You Contract Covid in the USA

SELECT Location, date, total_cases, total_deaths, cast(total_deaths as bigint)/NULLIF(cast(total_cases as float),0)*100 AS DeathPercentage_US
FROM PortfolioProjectX.dbo.CovidDeathsX
WHERE location like '%states%'
ORDER BY 1,2;

-- Total Cases vs Population(Shows What Percentage of Population Got Covid)

SELECT Location, date, population, total_cases, cast(total_cases as bigint)/NULLIF(cast(population as float),0)*100 AS PercentPopulationInfected
FROM PortfolioProjectX.dbo.CovidDeathsX
WHERE location like '%states%'
ORDER BY 1,2;


-- Looking at Countries With Highest Infection Rate Compared to Population

SELECT Location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population)) *100 AS PercentPopulationInfected
FROM PortfolioProjectX.dbo.CovidDeathsX
-- WHERE location like '%states%'
GROUP BY Population, Location
ORDER BY PercentPopulationInfected DESC;


-- Countries With Highest Death Count Per Population

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProjectX.dbo.CovidDeathsX
--WHERE location like '%states%'
WHERE continent is not NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;


-- Data Broken Down by Continent


-- Showing Continents With Highest Death Count Per Population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProjectX.dbo.CovidDeathsX
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- Global Numbers

SELECT date, SUM(cast(new_cases as bigint)) AS total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as float))/SUM(cast(new_cases as float))*100 AS DeathPercentage
FROM PortfolioProjectX.dbo.CovidDeathsX
WHERE continent is not null
ORDER BY 1,2;


-- Looking at Total Population vs Vaccinations


Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated, 
(RollingPeopleVaccinated/Population) * 100
FROM PortfolioProjectX.dbo.CovidDeathsX dea
JOIN PortfolioProjectX.dbo.CovidVaccinationsX vac
ON dea.location =  vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2, 3;

-- USE CTE for Calculation on Partition By in Previous Query

With PopsvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS 
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectX.dbo.CovidDeathsX dea
JOIN PortfolioProjectX.dbo.CovidVaccinationsX vac
ON dea.location =  vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2, 3
)

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM PopsvsVac


-- Using Temp Table for Calculation on Partition By in Previous Query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by  dea.location ORDER by dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectX.dbo.CovidDeathsX dea
JOIN PortfolioProjectX.dbo.CovidVaccinationsX vac
ON dea.location =  vac.location
AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population) * 100
FROM #PercentPopulationVaccinated

-- Creating View to Store Data for Later Visualizations


USE PortfolioProjectX 
GO
CREATE VIEW PercentPopulationVaccinated AS 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by  dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjectX.dbo.CovidDeathsX dea
JOIN PortfolioProjectX.dbo.CovidVaccinationsX vac
ON dea.location =  vac.location
AND dea.date = vac.date
WHERE dea.continent is not NULL