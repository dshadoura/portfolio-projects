-- INTERNATIONAL SOCCER GAMES from 1872 to 2021

-- Changing the data type of DATE from text to date

ALTER TABLE int_soccer_results
ALTER date TYPE date
USING date::date;

ALTER TABLE int_soccer_shootouts
ALTER date TYPE date
USING date::date;

------------------------------------------------------------------------------------------------------------------------

-- Looking into the number of games throughout the years

select to_char(date,'yyyy') as year,
       count(*) as count_games
from int_soccer_results
group by 1
order by 1;

------------------------------------------------------------------------------------------------------------------------

-- Looking into the score in the full time and the winner in the shootout (if applicable)

CREATE VIEW int_soccer_full_results AS

select r.date,
       r.tournament as tournament,
       r.home_team,
       r.away_team,
       concat(r.home_score,'-',r.away_score) as score,
       case when r.home_score > r.away_score then r.home_team
            when r.home_score < r.away_score then r.away_team
            else
               case when s.winner is null then 'No penalties'
               else s.winner
                end
       end as winner
from int_soccer_results r
left join int_soccer_shootouts s
on r.home_team = s.home_team and r.away_team = s.away_team and r.date = s.date
order by 1;

select *
from int_soccer_full_results;

-- Looking into the team with most wins on penalty shootouts

select winner as country,
       count(*) as wins
from int_soccer_shootouts
group by 1
order by 2 desc;

------------------------------------------------------------------------------------------------------------------------

-- Looking into Goals Scored vs Goals Received by teams on each tournament

with home as (
    select home_team,
           tournament,
           count(home_team) as home_games,
           sum(home_score) as goals_scored,
           sum(away_score) as goals_received
    from int_soccer_results
    group by 1,2),

    away as (
    select away_team,
           tournament,
           count(away_team) as away_games,
           sum(away_score) as goals_scored,
           sum(home_score) as goals_received
    from int_soccer_results
    group by 1,2)

select h.home_team as country,
       h.tournament,
       coalesce(h.home_games,0) + coalesce(a.away_games,0) as total_games,
       coalesce(h.goals_scored,0) + coalesce(a.goals_scored,0) as goals_scored,
       coalesce(h.goals_received,0) + coalesce(a.goals_received,0) as goals_received
from home h
left join away a
on h.home_team = a.away_team and h.tournament = a.tournament
order by 1,2;

------------------------------------------------------------------------------------------------------------------------

-- Looking into the history of tournaments

select distinct(tournament) as tournament,
                min(to_char(date,'yyyy')) as date
from int_soccer_results
group by 1
order by 2;

------------------------------------------------------------------------------------------------------------------------

-- Looking into the teams with most wins on each tournament

with top_winners as (select tournament,
                            winner,
                            count(winner) as count_wins,
                            row_number() over (partition by tournament order by count(winner) desc) as tournament_rank
                     from int_soccer_full_results
                     where winner != 'No penalties'
                     group by 1,2
                     order by 1,3 desc)
select tournament,
       winner as country,
       count_wins
from top_winners
where tournament_rank = 1
order by 1;

------------------------------------------------------------------------------------------------------------------------

-- Looking into Total Games

CREATE VIEW is_total_games as

with h as (select home_team,
       count(home_team) as home_games
from int_soccer_results
group by 1
order by 1),

a as (select away_team,
       count(*) as away_games
from int_soccer_results
group by 1
order by 1)

select h.home_team as country,
       h.home_games,
       a.away_games,
       h.home_games + a.away_games as total_games
from h
left join a
on h.home_team = a.away_team
order by 1;

select *
from is_total_games;

------------------------------------------------------------------------------------------------------------------------

--- Looking into Wins, Loses and Draws

with home_data as (select home_team,
       count(case when home_score > int_soccer_results.away_score then 1 end) as home_wins,
       count(case when home_score < int_soccer_results.away_score then 1 end) as home_loses,
       count(case when home_score = int_soccer_results.away_score then 1 end) as home_draws
from int_soccer_results
group by 1
order by 1),

away_data as (select away_team,
       count(case when home_score < int_soccer_results.away_score then 1 end) as away_wins,
       count(case when home_score > int_soccer_results.away_score then 1 end) as away_loses,
       count(case when home_score = int_soccer_results.away_score then 1 end) as away_draws
from int_soccer_results
group by 1
order by 1)

select hd.home_team as country,
       coalesce(hd.home_wins,0) + coalesce(ad.away_wins, 0) as wins,
       coalesce(hd.home_loses,0) + coalesce(ad.away_loses,0) as loses,
       coalesce(hd.home_draws,0) + coalesce(ad.away_draws,0) as draws,
       total_games
from home_data hd
left join away_data ad
on hd.home_team = ad.away_team
left join is_total_games itg
on hd.home_team = itg.country
order by 1;


