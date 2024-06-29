select * into Dataset from Datum;

-- Data Profiling:

---- Overall dataset
select * from Dataset;

---- Total_rows:

select count(*) as Total_rows from Dataset;

---- Columns in Dataset
select name as Datum from sys.columns where object_id=OBJECT_ID('Datum');
select name from sys.columns where object_id=OBJECT_ID('Dataset');

---- Statistical Summary:

SELECT
    MIN(TotalTonnes) AS min_value,
    MAX(TotalTonnes) AS max_value,
    AVG(TotalTonnes) AS mean_value,
    STDEVP(TotalTonnes) AS stddev_value
FROM Dataset;

---- Count of Particular Column
SELECT COUNT(DISTINCT Authority) AS distinct_values FROM Dataset;

SELECT COUNT(*) AS null_values FROM Dataset WHERE Authority IS NULL;
SELECT COUNT(*) AS null_values FROM Dataset WHERE TotalTonnes IS NULL;
SELECT COUNT(*) AS null_values FROM Dataset WHERE Period IS NULL;

-- Remove unnecessary data
alter table Dataset drop column NationalFacilityId, MonthlyComments, MaterialGroup;

-- Q1 : Total Authorities
select Authority, count(*) as Total_Authority
from Dataset Group by Authority having COUNT(*) >1;

-- Q2: Select top 10 “Dry recyclate” waste Materials processed and the total weight in TotalTonnes for each material quarters
SELECT TOP 10 Material,
    SUM(CASE 
            WHEN Period LIKE '%Apr%' OR Period LIKE '%May%' OR Period LIKE '%Jun%' THEN TotalTonnes 
            ELSE 0 
        END) AS Apr_Jun_Total,
    SUM(CASE 
            WHEN Period LIKE '%Jul%' OR Period LIKE '%Aug%' OR Period LIKE '%Sep%' THEN TotalTonnes 
            ELSE 0 
        END) AS Jul_Sep_Total,
    SUM(CASE 
            WHEN Period LIKE '%Oct%' OR Period LIKE '%Nov%' OR Period LIKE '%Dec%' THEN TotalTonnes 
            ELSE 0 
        END) AS Oct_Dec_Total,
    SUM(CASE 
            WHEN Period LIKE '%Jan%' OR Period LIKE '%Feb%' OR Period LIKE '%Mar%' THEN TotalTonnes 
            ELSE 0 
        END) AS Jan_Mar_Total
FROM Dataset WHERE OutputProcessType = 'Dry recyclate' 
GROUP BY Material ORDER BY SUM(TotalTonnes) DESC;



-- Q3: Lowest 5 authorities & Total Tonnes of waste processed by each of these for six month period 
-- & number of places each authority has moved since previous period

with RankedAuthorities as ( select Authority, Period, sum(TotalTonnes) as TotalTonnes, row_number() 
	over (partition by Period order by sum(TotalTonnes) asc) as Ranking 
	from Dataset Group by Authority, Period) select Authority, Period, TotalTonnes, Ranking, 
    case 
        when lag(Ranking) over (partition by Authority order by Period) is null then null
        else Ranking - lag(Ranking) over (partition by Authority order by Period)
    end as Movement 
from RankedAuthorities where Ranking <= 5 order by Period, Ranking;


-- Q4: For each FacilityType show the WasteStreamType, TotalTonnesFromHH 
-- (households) reported for the period order the output in descending order of TotalTonnesFromHH.

select distinct([FacilityType]), [WasteStreamType], sum(TonnesFromHHSources) as TotalTonnesfromHH from Dataset 
where Period is not null
group by FacilityType, WasteStreamType
Order by TotalTonnesfromHH DESC;


--Q5: shows the monthly TotalTonnes processed for each OutputProcessType
select  OutputProcessType, Authority, sum(TotalTonnes) as Total_tonnes, Period,
	sum(CASE 
				WHEN Period LIKE '%Apr%' OR Period LIKE '%May%' OR Period LIKE '%Jun%' THEN TotalTonnes 
				ELSE 0 
			END) AS Apr_Jun_Total,
	sum(case
				WHEN Period LIKE '%Jul%' OR Period LIKE '%Aug%' OR Period LIKE '%Sep%' THEN TotalTonnes 
				ELSE 0 
			END) AS Jul_Sep_Total,
	sum(case
				WHEN Period LIKE '%Oct%' OR Period LIKE '%Nov%' OR Period LIKE '%Dec%' THEN TotalTonnes 
				ELSE 0 
			END) AS Oct_Nov_Total,
	sum(case
				WHEN Period LIKE '%Jan%' OR Period LIKE '%Feb%' OR Period LIKE '%Mar%' THEN TotalTonnes 
				ELSE 0 
			END) AS Jan_Mar_Total
from Dataset Group by OutputProcessType, TotalTonnes, Authority, Period order by OutputProcessType, Total_tonnes Desc;



