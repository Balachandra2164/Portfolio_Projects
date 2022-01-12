/*Covid 19 data exploration*/
--Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

select top 500 * from PortfolioProject.dbo.coviddeaths 
where continent is not null
order by 3,4

select  top 500 * from PortfolioProject..covidvaccinations
where continent is not null 

--select data that we are going to starting with
select location,date,total_cases,new_cases,total_deaths
from PortfolioProject..coviddeaths
where continent is not null
order by 1,2

--Total cases vs total_deaths
--show likelihood of dying if you contract covid in your country
select location,date,total_cases,total_deaths,(total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..coviddeaths
where location like '%states%' and continent is not null
order by 1,2

--Total cases vs population
select location,date,total_cases,population,(total_cases/population)*100 as PercentPopulationInfect
from PortfolioProject..coviddeaths
where continent is not null
order by 1, 2

--Countries with highest infectionrate compared to population
select location,max(total_cases) as HighestInfectionCount ,population,
(max(total_cases)/population)*100 as PercentPopulationInfect
from PortfolioProject..coviddeaths
where continent is not null
group by location,population
order by PercentPopulationInfect desc

--Countried with highest death count per population
select location,max(convert(int,total_deaths)) HighestDeathCount,population from PortfolioProject..coviddeaths 
where continent is not null
--and location like'%di%'
group by location,population
order by 2 desc

--Breaking things down by continent

--showing the continent with highest death count per population
select continent,max(convert(int,convert(int,total_deaths))) HighestDeathCount
from PortfolioProject..coviddeaths 
where continent is not null
--and location like'%di%'
group by continent
order by 2 desc

--global numbers
select sum(new_cases) as Totalcases, sum(cast(new_deaths as int)) TotalDeaths,
sum(cast(new_deaths as int)) /sum(new_cases)*100 as DeathPercentage
from PortfolioProject..coviddeaths
where continent is not null
--where location='India'
--group by location
order by DeathPercentage

--Exploring the covid vaccination dataset
select location, date,population,cast(new_vaccinations as int) as VaccinationConunt from PortfolioProject..covidvaccinations
where continent is not null
order by 1,2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

select dea.continent,dea.location,dea.date,dea.population,cast(vac.new_vaccinations as numeric(22,7)) new_vaccinations,
sum(convert(numeric(22,7),vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated 
from
PortfolioProject..coviddeaths dea
join PortfolioProject..covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null --and dea.location='India'
order by 2,3--dea.date asc

--Using CTE to perform calculation on partition by previous query

With PopvsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as 
(
select dea.continent,dea.location,dea.date,dea.population,cast(vac.new_vaccinations as numeric(22,7)) new_vaccinations,
sum(convert(numeric(22,7),vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated 
from
PortfolioProject..coviddeaths dea
join PortfolioProject..covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null --and dea.location='India'
--order by 2,3
)
select *,(RollingPeopleVaccinated/population)*100 as RollingPeopleVaccinated from PopvsVac



--Using Temp Table to perform calculation on partition by in the previous query
drop table if exists #PercentPopulationVaccinate
create table #PercentPopulationVaccinate
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
--select * from #PercentPopulationVaccinate
insert into #PercentPopulationVaccinate
select dea.continent,dea.location,dea.date,dea.population,cast(vac.new_vaccinations as numeric(22,7)) new_vaccinations,
sum(convert(numeric(22,7),vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated 
from
PortfolioProject..coviddeaths dea
join PortfolioProject..covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null 


select * ,(RollingPeopleVaccinated/population)*100 PercentPeopleVaccinated from #PercentPopulationVaccinate
--where location='India'


--Creating view to store data for later visualization
drop view if exists PercentPopulationVaccinated
create view PercentPopulationVaccinated as
select dea.continent,dea.location,dea.date,dea.population,cast(vac.new_vaccinations as numeric(22,7)) new_vaccinations,
sum(convert(numeric(22,7),vac.new_vaccinations)) over (partition by dea.location order by dea.location,dea.date) as RollingPeopleVaccinated 
from PortfolioProject..coviddeaths dea
join PortfolioProject..covidvaccinations vac
on dea.location=vac.location
and dea.date=vac.date
where dea.continent is not null 

select * from PercentPopulationVaccinated