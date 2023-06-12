/*
COVID 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types (cast / CONVERT)
*/

-- COVID DEATH DATA

-- Overall data from CovidDeaths Table
Select *
From PortfolioProjectCovid..CovidDeaths
Where continent is not null
Order By 3, 4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProjectCovid..CovidDeaths
Order By 1, 2


-- Looking at Total Cases vs Total Deaths
-- Shows the likelihood of dying if you contract COVID in the United States

Select Location, date, total_cases, total_deaths, (cast(total_deaths as float) / cast(total_cases as float)) * 100 as DeathPercentage
From PortfolioProjectCovid..CovidDeaths
Where Location = 'United States' and continent is not null
Order By 1, 2


-- Looking at Total Cases vs Population
--Shows percentage of population that contracted Covid in the United States

Select Location, date, Population, total_cases, (total_cases / Population) * 100 as PercentageOfPopulationInfected
From PortfolioProjectCovid..CovidDeaths
Where Location = 'United States' and continent is not null
Order By 1, 2


-- Looking at countries with highest infection rate vs population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases) / Population) * 100 as PercentageOfPopulationInfected
From PortfolioProjectCovid..CovidDeaths
Where continent is not null
Group By location, population
Order By PercentageOfPopulationInfected desc


-- Looking at countries with highest death count per population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjectCovid..CovidDeaths
Where continent is not null
Group By location
Order By TotalDeathCount desc



-- CONTENENT NUMBERS

-- Looking at Death Count per Contenent

Select location, MAX(cast(total_deaths as int)) as TotalDeathCount
From PortfolioProjectCovid..CovidDeaths
Where continent is null and location not like '%income%' -- Filters out data reported in continets, but is actually income brackets
Group By location
Order By TotalDeathCount desc



-- GLOBAL NUMBERS

-- Global numbers by date
Select date, SUM(cast(new_cases as float)) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths) / SUM(cast(new_cases as float)) * 100 as DeathPercentage
From PortfolioProjectCovid..CovidDeaths
Where continent is not null and new_cases <> 0 -- Filters out divide by zero error and overall continent numbers
Group by date
Order By 1, 2

-- Overall global numbers
Select SUM(cast(new_cases as float)) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths) / SUM(cast(new_cases as float)) * 100 as DeathPercentage
From PortfolioProjectCovid..CovidDeaths
Where continent is not null and new_cases <> 0 -- Filters out divide by zero error and overall continent numbers
Order By 1, 2



-- COVID VACCINATION DATA

-- Overall data
Select *
From PortfolioProjectCovid..CovidVaccinations

-- Joining CovidDeaths with CovidVaccinations
Select *
From PortfolioProjectCovid..CovidDeaths as deaths
Join PortfolioProjectCovid..CovidVaccinations as vacc
	On deaths.location = vacc.location and deaths.date = vacc.date

-- Looking at Total Population vs Population Vaccinationed
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as RollingCountOfVaccinatedPopulation
From PortfolioProjectCovid..CovidDeaths as deaths
Join PortfolioProjectCovid..CovidVaccinations as vacc
	On deaths.location = vacc.location and deaths.date = vacc.date
Where deaths.continent is not null
Order By  2, 3

-- Looking at Total Population vs Population Vaccinationed USING CTE
With PopVsVacc (continent, location, date, population, new_vaccinations, RollingCountOfVaccinatedPopulation)
as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(CONVERT(bigint, vacc.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as RollingCountOfVaccinatedPopulation
From PortfolioProjectCovid..CovidDeaths as deaths
Join PortfolioProjectCovid..CovidVaccinations as vacc
	On deaths.location = vacc.location and deaths.date = vacc.date
Where deaths.continent is not null
)
Select *, (RollingCountOfVaccinatedPopulation / population) * 100 as RollingPercentageOfPopulationVaccinated
From PopVsVacc

-- Looking at Total Population vs Population Vaccinationed USING TEMP TABLE
DROP Table if exists #PercentOfPopulationVaccinated
Create Table #PercentOfPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPercentageOfPopulationVaccinated numeric
)

Insert into #PercentOfPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as RollingCountOfVaccinatedPopulation
From PortfolioProjectCovid..CovidDeaths as deaths
Join PortfolioProjectCovid..CovidVaccinations as vacc
	On deaths.location = vacc.location and deaths.date = vacc.date
Where deaths.continent is not null

Select *, (RollingPercentageOfPopulationVaccinated / Population) * 100
From #PercentOfPopulationVaccinated

-- CREATING VIEWS TO STORE DATA FOR LATER VISUALIZATION

-- Percent of Population Vaccinated
Create View PercentofPopulationVaccinated as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vacc.new_vaccinations
, SUM(Convert(bigint, vacc.new_vaccinations)) OVER (Partition by deaths.location Order by deaths.location, deaths.date) as RollingCountOfVaccinatedPopulation
From PortfolioProjectCovid..CovidDeaths as deaths
Join PortfolioProjectCovid..CovidVaccinations as vacc
	On deaths.location = vacc.location and deaths.date = vacc.date
Where deaths.continent is not null
