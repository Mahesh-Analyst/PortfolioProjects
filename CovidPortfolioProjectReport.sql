-- SELECT DATA WE ARE GOING TO USE
Select 
	location, 
    date, 
    total_cases, 
    new_cases, 
    population
from 
coviddeaths;

-- LOOKIG AT TOTAL CASES VS TOTAL DEATHS
Select 
	location, 
	date, 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases)*100 as DeathPercentage
from 
	coviddeaths
where 
	location= 'India';

-- Looking Total Cases Vs Population
-- Shows what percentage of population got covid
Select 
	location, 
	date, 
    population, 
    total_cases, 
    (total_cases/population)*100 as PercentagePopulationInfected
from 
	coviddeaths
where 
	location= 'India';

-- Looking At Countries With Highest Infection Rates compared to population
Select 
	location, 
	population, 
    max(total_cases) as HighestInfectedCount, 
    Max((total_cases/population))*100 as PercentagePopulationInfected
from 
	coviddeaths
group by 
	location, population
order by 
	PercentagePopulationInfected desc;

-- Showing countries with highest covid deaths per population
SELECT 
	location, 
    MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM 
	coviddeaths
WHERE 
	continent IS NOT NULL AND continent <> ''
GROUP BY 
	location
ORDER BY 
	TotalDeathCount DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT 
-- Showing continents with highest covid deaths per population
SELECT 
	continent, 
	MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM 
	coviddeaths
WHERE 
	continent IS NOT NULL AND continent <> ''
GROUP BY 
	continent
ORDER BY 
	TotalDeathCount DESC;

-- GLOBAL DATA 
Select 
	date, 
    sum(new_cases) as total_cases, 
    sum(cast(new_deaths as signed)) as total_deaths, 
    (sum(cast(new_deaths as signed))/sum(new_cases))*100 as DeathPercentage
from 
	coviddeaths
WHERE 
	continent IS NOT NULL AND continent <> ''
group by date;


-- LOOKING AT TOTAL POPULATION VS VACCINATIONS
select 
	dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    dea.new_cases, 
    vac.new_vaccinations
from 
	portfolioproject.coviddeaths dea
join 
	portfolioproject.covidvaccinations vac
	on dea.location = vac.location
    AND dea.date = vac.date
where 
	dea.continent is not null;

-- SHOWING ROLLING COUNT OF PEOPLE VACCINATED
select 
	dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
from 
	portfolioproject.coviddeaths dea
join 
	portfolioproject.covidvaccinations vac
	on dea.location = vac.location
    AND dea.date = vac.date
where 
	dea.continent <> '';

-- USE CTE

with PopVsVac 
	(Continent, Location, Date, Population, New_Vaccinations, RollingVaccinationCount)
as 
(
select 
	dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as signed)) over (partition by dea.location order by dea.location, dea.date) as RollingVaccinationCount
from 
	portfolioproject.coviddeaths dea
join 
	portfolioproject.covidvaccinations vac
	on dea.location = vac.location
    AND dea.date = vac.date
where dea.continent <> ''
)
select *, 
	(RollingVaccinationCount/population)*100
from 
	PopVsVac;

drop table PercentPopulationVaccinated;
-- TEMP TABLE

-- Create the temporary table
DROP TABLE IF exists PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated 
(
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC,
    RollingVaccinationCount NUMERIC
);

-- Insert data into the temporary table with correct date format and handling empty population values
INSERT INTO PercentPopulationVaccinated
SELECT
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%d/%m/%Y'), -- Convert the date to 'YYYY-MM-DD' format
    CAST(NULLIF(dea.population, '') AS SIGNED), -- Convert empty values to NULL and then to numeric
    CASE WHEN vac.new_vaccinations <> '' THEN vac.new_vaccinations ELSE NULL END as New_Vaccinations,
    SUM(CASE WHEN vac.new_vaccinations <> '' THEN CAST(vac.new_vaccinations AS SIGNED) ELSE 0 END) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%d/%m/%Y')) AS RollingVaccinationCount
FROM
    portfolioproject.coviddeaths dea
JOIN
    portfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent <> '';

-- Calculate the percentage of the population vaccinated
SELECT
    *,
    (RollingVaccinationCount / Population) * 100 AS PercentVaccinated
FROM
    PercentPopulationVaccinated;


-- CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS 
SELECT
    dea.continent,
    dea.location,
    STR_TO_DATE(dea.date, '%d/%m/%Y'), -- Convert the date to 'YYYY-MM-DD' format
    CAST(NULLIF(dea.population, '') AS SIGNED), -- Convert empty values to NULL and then to numeric
    CASE WHEN vac.new_vaccinations <> '' THEN vac.new_vaccinations ELSE NULL END as New_Vaccinations,
    SUM(CASE WHEN vac.new_vaccinations <> '' THEN CAST(vac.new_vaccinations AS SIGNED) ELSE 0 END) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, STR_TO_DATE(dea.date, '%d/%m/%Y')) AS RollingVaccinationCount
FROM
    portfolioproject.coviddeaths dea
JOIN
    portfolioproject.covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent <> '';
    
select *
from PercentPopulationVaccinated;


