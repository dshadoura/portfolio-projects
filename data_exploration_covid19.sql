--DATA EXPLORATION - COVID-19

------------------------------------------------------------------------------------------------------------------------

--DATA BY COUNTRY

--Looking at Total Cases vs Total Deaths

select location, 
date, 
population, 
total_cases, 
total_deaths, 
((total_deaths / total_cases)) * 100 as death_rate 
from "dshadoura/Portfolio".covid_deaths 
order by 1, 2

------------------------------------------------------------------------------------------------------------------------

-- Looking at countries highest infection rate compared to population

select location,
population,
max(total_cases) as highest_infection_count,
max((total_cases/population)*100) as percent_population_infected
from "dshadoura/Portfolio"."covid_deaths"
group by 1,2
order by 4 desc nulls last

------------------------------------------------------------------------------------------------------------------------

-- Looking at countries with Highest Deaths Count per Population

select location,
max(total_deaths) as total_deaths_count
from "dshadoura/Portfolio"."covid_deaths"
where continent is not null
group by 1
order by 2 desc nulls last

-- Looking at Total Population vs Total People Vaccinated

with pop_vac (date, location, population, new_vaccinations, people_vaccinated)
as
(
select dea.date,
dea.location,
dea.population,
vac.new_vaccinations,
sum(cast(new_vaccinations as int)) over (partition by dea.location order by dea.location, dea.date) as people_vaccinated
from "dshadoura/Portfolio"."covid_deaths" dea 
join "dshadoura/Portfolio"."covid_vaccinations" vac
on dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
)

select *,
(people_vaccinated / population) * 100 as percentage_population_vaccinated
from pop_vac 

------------------------------------------------------------------------------------------------------------------------

--DATA BY CONTINENT

--Looking at Total Cases vs Total Deaths

select location as continent,
max(total_deaths) as total_deaths_count
from "dshadoura/Portfolio"."covid_deaths"
where continent is null
group by 1
order by 2 desc nulls last 


------------------------------------------------------------------------------------------------------------------------

--- GLOBAL DATA

select date,
sum(new_cases) as total_cases,
sum(new_deaths) as total_deaths,
(sum(new_deaths)/sum(new_cases))*100 as death_rate
from "dshadoura/Portfolio".covid_deaths
where continent is not null
group by 1
order by 1 asc 

------------------------------------------------------------------------------------------------------------------------

-- CREATING A VIEW TO STORE DATA FOR LATER VIZUALIZATIONS

CREATE VIEW global_data as

select date,
sum(new_cases) as total_cases,
sum(new_deaths) as total_deaths,
(sum(new_deaths)/sum(new_cases))*100 as death_rate
from "dshadoura/Portfolio".covid_deaths
where continent is not null
group by 1
order by 1 asc ;

