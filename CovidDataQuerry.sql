
--1. What is the death rate per covid case for each day in Countries?
		
select
	location, 
	date, 
	total_cases,
	total_deaths,
	population,
	(total_deaths/total_cases)*100 as Death_Percentage
from
	CovidDeaths
where 
	continent is not null   
order by 
	1,6 desc

--2. What is the overall  percentage of death per total cases in Country
select 
	location,
	population,
	max(total_cases) as Total_Covid_Case,
	max(cast(total_deaths as int)) as Total_Covid_Death, 
	max(cast(total_deaths as int)) /max(total_cases) *100 as Percent_death_per_Case
from 
	CovidDeaths
where  
	continent is not null 
group by
	location, population
order by
	4 desc

--3. What country has the highest infection rate compared to the population?
		--Answer: Andorra had the highest with about 17.1 % population infected
select 
	location,
	population, 
	max(total_cases) as HighestInfectionCount,
	max((total_cases/population)*100) as PercentagePopulationInfected
from 
	CovidDeaths
where  
	continent is not null 
group by
	location,
	population
order by 
	4 desc  
--4. What country has the highest death rate per to the population?
		--Answer: Hungary has highest with about 0.28% death by population
select 
	location,
	population, 
	max(cast(total_deaths as int)) as Highest_Death_Count,
	max(cast(total_deaths as int) /population*100 ) as Percentage_Population_Death
from 
	CovidDeaths
where  
	continent is not null  
group by
	location,
	population
order by 
	4 desc 

--5. What continent has the higest death count of Covid?
	
select
	continent,  
	max(cast (total_deaths as int)) as TotalDeathCount
from
	CovidDeaths
where  
	continent is not null 
group by 
	continent
order by 
	2 desc

--6.  What is the global covid cases and death each day?
select 
	date,  
	sum(new_cases) as Total_Cases, 
	sum( cast(new_deaths as int)) as Total_Death, 
	(sum( cast(new_deaths as int))/sum(new_cases))*100 as Percent_Death_Per_Cases
from 
	CovidDeaths
where 
	continent is not null 
group by
	date
order by 
	3 desc

--7. What is the global covid cases and death?
select 
	sum(new_cases) as Total_Cases, 
	sum( cast(new_deaths as int)) as Total_Death, 
	(sum( cast(new_deaths as int))/sum(new_cases))*100 as PercentageDeathPerCases
from
	CovidDeaths
where 
	continent is not null 
order by
	1,2 desc


--8. what percentage of total population were vaccinated (Using CTE and TEM table and joins)
	-- 8a. With table (CTE)

with PopVsVac
	(continent,location, date,population ,new_vaccinations,RollingPeopleVaccinated)
	as
		(
			select	
				dea.continent,
				dea.location, 
				dea.date, 
				dea.population,
				vac.new_vaccinations,
				sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
			from 
				CovidDeaths dea
			join 
				CovidVaccinations vac
				on dea.location=vac.location and
					dea.date=vac.date
			where  dea.continent is not null
		)
select
	continent,
	location,
	date,
	population,
	new_vaccinations,
	RollingPeopleVaccinated, 
	(RollingPeopleVaccinated/population)*100 as percent_Population_vaccinated
from 
	PopVsVac


	--8bi. Temp table (Method 1)
drop table if exists 
	#PercentPopulationVaccinated
create table
	#PercentPopulationVaccinated
	(
		continent nvarchar(255),
		location nvarchar(250),
		date datetime,
		population numeric,
		new_vaccinations numeric,
		RollingPeopleVaccinated numeric
	)
insert into
	#PercentPopulationVaccinated
select 
	dea.continent,
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated

from 
	CovidDeaths dea
join 
	CovidVaccinations vac
on 
	dea.location=vac.location and
	dea.date=vac.date
where  
	dea.continent is not null

select 
	*, 
	(RollingPeopleVaccinated/population) * 100 as PopulationVaccinated
from 
	#PercentPopulationVaccinated

go 

drop view if exists  
	PercentPopulationVaccinated
go

	--8bii. Temp table (Method 2)

drop table if exists 
	#PercentPopulationVaccinated
select 
	dea.continent,
	dea.location, 
	dea.date,
	dea.population,
	vac.new_vaccinations,
	sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
into 
	#PercentPopulationVaccinated
from 
	CovidDeaths dea
join 
	CovidVaccinations vac
on 
	dea.location=vac.location and
	dea.date=vac.date
where  
	dea.continent is not null

select 
	*, 
	(RollingPeopleVaccinated/population) * 100 as PopulationVaccinated
from 
	#PercentPopulationVaccinated


--9. Creating views for visualization
		--9a. view for question 8 (what percentage of total population were vaccinated)

drop view if exists PercentPopulationVaccinated
go
Create view 
	PercentPopulationVaccinated as 
	(select
		dea.continent,
		dea.location,
		dea.date, dea.population,
		vac.new_vaccinations,
		sum(convert(int,vac.new_vaccinations)) over (partition by dea.location  order by dea.location, dea.date) as RollingPeopleVaccinated
	from
		CovidDeaths dea
	join 
		CovidVaccinations vac
	on
		dea.location=vac.location and
		dea.date=vac.date
	where  
		dea.continent is not null)
go 
select
	*
from 
	PercentPopulationVaccinated

	--9b. View for question 4 (What country has the highest death rate per to the population?)
drop view if exists 
	Percentage_Death_per_Population
go
create view
	Percentage_Death_per_Population as 
	(select 
		location,
		population, 
		max(cast(total_deaths as int)) as Highest_Death_Count,
		max(cast(total_deaths as int) /population*100 ) as Percentage_Population_Death
	from 
		CovidDeaths
	where  
		continent is not null  
	group by
		location,
		population
	 )
go
select
	*
from 
	Percentage_Death_per_Population
	order by 4 desc
	
