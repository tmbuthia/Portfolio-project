-- Table: public.covid_vaccinations

-- DROP TABLE IF EXISTS public.covid_vaccinations;

DROP TABLE 	covid_vaccinations;

CREATE TABLE IF NOT EXISTS public.covid_vaccinations
(
iso_code VARCHAR(40),
continent VARCHAR(40),
location VARCHAR(40),
date DATE,
population FLOAT,
total_tests FLOAT,
new_tests FLOAT,
total_tests_per_thousand FLOAT,
new_tests_per_thousand FLOAT,
new_tests_smoothed FLOAT,
new_tests_smoothed_per_thousand FLOAT,
positive_rate FLOAT,
tests_per_case FLOAT,
tests_units FLOAT,
total_vaccinations FLOAT,
people_vaccinated FLOAT,
people_fully_vaccinated FLOAT,
total_boosters FLOAT,
new_vaccinations FLOAT,
new_vaccinations_smoothed FLOAT,
total_vaccinations_per_hundred FLOAT,
people_vaccinated_per_hundred FLOAT,
people_fully_vaccinated_per_hundred FLOAT,
total_boosters_per_hundred FLOAT,
new_vaccinations_smoothed_per_million FLOAT,
new_people_vaccinated_smoothed FLOAT,
new_people_vaccinated_smoothed_per_hundred FLOAT,
stringency_index FLOAT,
population_density FLOAT
)

ALTER TABLE covid_vaccinations
ALTER COLUMN tests_units TYPE VARCHAR(50);

select * FROM covid_deaths;
select * FROM covid_vaccinations;
--looking at total cases vs total deaths

SELECT location,date,total_cases,total_deaths,population,(total_cases/population)*100 as DeathPercentage
FROM covid_deaths
Where continent is not null
--AND location like '%States%'
order by 1,2;
--loooking at countries with highest infection rate compared to population

Select location, population,MAX(total_cases) as Highestinfectioncount,
MAX((total_cases/population)*100) as PercentPouplationInfected
FROM covid_deaths
WHERE continent is not null
Group by location,population
order by PercentPouplationInfected desc;

--Showing countries with the Highest death count per population
Select location, MAX(cast(total_deaths as int)) as Totaldeathcount
FROM covid_deaths
WHERE continent is not null
Group by location,population
order by Totaldeathcount desc;

--loooking at countries with highest infection rate compared to population in time series/date
Select location,continent,date, population,MAX(total_cases) as Highestinfectioncount,
MAX((total_cases/population)*100)  as PercentPouplationInfected
FROM covid_deaths
WHERE continent is not null
Group by continent,location,population,date
order by PercentPouplationInfected,date desc;

-- Lets break things down by continent
Select continent, MAX(cast(total_deaths as int)) as Totaldeathcount
FROM covid_deaths
WHERE continent is not null
Group by continent
order by Totaldeathcount desc;

--showing continents with the highest death count per population
Select continent, MAX(cast(total_deaths as int)) as Totaldeathcount
FROM covid_deaths
WHERE continent is not null
Group by continent
order by Totaldeathcount desc;

--Getting global numbers
select SUM(new_cases) AS total_cases, SUM(new_deaths)as total_deaths,
SUM(new_deaths)/sum(new_cases)*100 as DeathPercentage
FROM covid_deaths
WHERE continent is not null
--Group by date
order by 1,2;

--Looking at total populations vs vaccinations
WITH PopvsVac(Continent,location,date,population,new_vaccinations,RollingVacinatedPeople)
AS
(
Select d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(new_vaccinations) OVER (Partition by d.location order by d.location,d.date) AS RollingVacinatedPeople
FROM covid_deaths d
JOIN covid_vaccinations v
	ON d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3
)
SELECT *,(RollingVacinatedPeople/population)*100 AS percentvacinatedpopulation
FROM PopvsVac;

--TEMP TABLE
Drop view if exists percentvaccinatedpopulation;
drop table percentvaccinatedpopulation;
Create table percentvaccinatedpopulation
(
continent varchar(255),
location varchar(255),
Date date,
population numeric,
new_vaccinations numeric,
RollingVacinatedPeople numeric
);
	
INSERT INTO percentvaccinatedpopulation
Select d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(new_vaccinations) OVER (Partition by d.location order by d.location,d.date) AS RollingVacinatedPeople
FROM covid_deaths d
JOIN covid_vaccinations v
	ON d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3;

SELECT *
FROM percentvaccinatedpopulation;


--Create view to store data for later visualizations
Create view percentpopulationvaccinated AS
Select d.continent,d.location,d.date,d.population,v.new_vaccinations,
SUM(new_vaccinations) OVER (Partition by d.location order by d.location,d.date) AS RollingVacinatedPeople
FROM covid_deaths d
JOIN covid_vaccinations v
	ON d.location = v.location
	and d.date = v.date
where d.continent is not null
order by 2,3
select * from percentpopulationvaccinated;
Create table popstat
(
iso_code varchar(50),
continent varchar(50),
location varchar(100),
Date date,
population_density numeric,
gdp_per_capita numeric,
population numeric,
median_age numeric
);
drop table hospitalization;
drop view  covidspread;
select * from popstat;

Create view covidspread AS
Select d.continent,d.location,d.population,d.new_cases,p.population_density,p.median_age,
SUM(new_cases) OVER (Partition by d.location order by d.location, d.date) AS Rollingcases
FROM covid_deaths d
JOIN popstat p
	ON d.location = p.location
	and d.date = p.date
where d.continent is not null
order by 2,3;

SELECT DISTINCT location,MAX(Rollingcases) OVER (PARTITION BY location) as total_cases,population_density,median_age 
FROM covidspread;