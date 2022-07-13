/****** Script for SelectTopNRows command from SSMS  ******/
SELECT *
  FROM [portfolioProject].[dbo].[CovidDeath]
  order by 3,4

  --SELECT *
  --FROM [portfolioProject].[dbo].[Covidvac]
  --order by 3,4

  --select the data we wanna work on :- location , dates, total_cases, new_cases, total_deaths, population 
Select Location, date, total_cases, new_cases, total_deaths, population --selecting needed coloum
  from [portfolioProject].[dbo].[CovidDeath]
  order by 1,2 --ordering it by location and date

  --looking at total cases vs total death for entire cases (in %) it will show likelihood of dying if u contract covid i your country
  Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
  from [portfolioProject].[dbo].[CovidDeath]
  where location like '%states%'
  order by 1,2 

  --looking at the totoal cases and the population
  Select Location, date, total_cases, total_deaths,population,(total_cases/population)*100 as InfectedPopulation, (total_deaths/total_cases)*100 as DeathPercentage
  from [portfolioProject].[dbo].[CovidDeath]
  --where location like '%states%'
  order by 1,2 

  --country with highest infection rate compared to population 
Select location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as InfectedPopulation
  from [portfolioProject].[dbo].[CovidDeath]
  Group by location,population
  order by 4 desc

  --counties with highest death count per population 
  Select location, MAX(total_deaths) as TotalDeathCount
  from [portfolioProject].[dbo].[CovidDeath]
  Group by location,total_deaths
  order by 2 desc
  -- it will give error becoz total_ddeaths is set as var(255)

   Select location, MAX(cast (total_deaths as int)) as TotalDeathCount ---- setting it as int for correcting sorting
  from [portfolioProject].[dbo].[CovidDeath]
  Group by location
  order by 2 desc
  -- now the problem arises with the location , contenents are also grouped and giving the summed up numbers

  -- we have some continents with NULL values, lets remove that 
  select location, MAX(cast (total_deaths as int)) as TotalDeathCount 
  from [portfolioProject].[dbo].[CovidDeath]
  where continent is not null
  Group by location
  order by 2 desc

  -- lets have numbers for each continent 
    select continent, MAX(cast (total_deaths as int)) as TotalDeathCount 
  from [portfolioProject].[dbo].[CovidDeath]
  where continent is not null
  Group by continent
  order by 2 desc
  -- now the issue is north america is just showing number for america only not of canada and US 

  -- to correct it , we have to select location where continent is null and grp it by location 
select location, MAX(cast (total_deaths as int)) as TotalDeathCount 
  from [portfolioProject].[dbo].[CovidDeath]
  where continent is null
  Group by location
  order by 2 desc

  -- now just fatch out the global number totalling every countries;s number 
  select date, sum(new_cases) as TotalCases, Sum(cast (new_deaths as int)) as TotalDeath, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
  from [portfolioProject].[dbo].[CovidDeath]
  where continent is not null
  Group by date
  order by 1

  -- now check the fatality rate of covid 19 of total cases ever
  select sum(new_cases) as TotalCases, Sum(cast (new_deaths as bigint)) as TotalDeath, sum(cast(new_deaths as bigint))/sum(new_cases)*100 as DeathPercentage
  from [portfolioProject].[dbo].[CovidDeath]
  where continent is not null
  --Group by date
  order by 1,2

 
 --looking at total population vs vaccinations 

	--first join table
  select *
  From [portfolioProject].[dbo].[CovidDeath] dea
  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date

	--looking at total population vs vaccinataions
 select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
  From [portfolioProject].[dbo].[CovidDeath] dea
  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date
  where dea.continent is not null
  order by 2,3

  --total rolling vaccinataions each day 
 select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations,
		sum(cast(vac.new_vaccinations as bigint)) OVER (partition by dea.location order by dea.location,dea.date) as VaccinationsSofar
  From [portfolioProject].[dbo].[CovidDeath] dea
  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date
  where dea.continent is not null
  order by 2,3


  --putting total vaccinations vs vaccination so far 
		-- use CTE
with PopvsVac (continent, location, date, population,new_vaccinations, VaccinationsSofar)
as
(
   select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM ( convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as VaccinationsSofar
  
  From [portfolioProject].[dbo].[CovidDeath] dea
  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date
  where dea.continent is not null
  --order by 2,3
  )
  select * 
  from PopvsVac

		--now use VaccinationsSoFar in calculation
with PopvsVac (continent, location, date, population,new_vaccinations, VaccinationsSofar)
as
(
   select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM ( convert(bigint,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as VaccinationsSofar
  
  From [portfolioProject].[dbo].[CovidDeath] dea
  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date
  where dea.continent is not null
  --order by 2,3
  )
  select *,(VaccinationsSofar/population)*100
  from PopvsVac



  --temp table
drop table if exists #percentPopulationVaccinated
create Table #percentPopulationVaccinated
		(
			Continent nvarchar(255),
			location nvarchar(255),
			date datetime,
			population numeric,
			new_vaccinations numeric,
			VaccinationsSofar numeric
		)

insert into #percentPopulationVaccinated

select 
			dea.Continent,
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			SUM ( convert(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as VaccinationsSofar
  
  From [portfolioProject].[dbo].[CovidDeath] dea

  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date

  --where dea.continent is not null
  --order by 2,3

  select *,(VaccinationsSofar/population)*100
  from #percentPopulationVaccinated

  -- creating view to store data for later visuallization 

  create view percentPopulationVaccinated as
  select 
			dea.Continent,
			dea.location,
			dea.date,
			dea.population,
			vac.new_vaccinations,
			SUM ( convert(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location,dea.date) as VaccinationsSofar
  
  From [portfolioProject].[dbo].[CovidDeath] dea

  join [portfolioProject].[dbo].[CovidVac] vac
  on dea.location= vac.location
  and dea.date=vac.date

  where dea.continent is not null
  --order by 2,3