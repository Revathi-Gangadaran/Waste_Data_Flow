# Waste Data Flow Managment
## Project Overview:
This project focuses on analysing the Waste data flow of 2015 - 2016 in United Kingdom. The dataset contains statistical data covering collection and recycling of waste based on a quarterly survey from local authorities. Data cleaning and transformation were performed using SQL Server. Utilised window functions to find some insights from the dataset.

## Contents:
- `Q100_data_England_2015_2016`: The dataset is in csv format.
- `README.md`: Documentation file providing an overview of the project and analysis steps.
- `Query.SQL`: SQL Query used for data cleaning, transformation and finding insights

## Prerequisite:
- Dataset - Wate Data Flow.[Download here](http://data.defra.gov.uk/Waste/Q100_data_England_2015_2016.csv) 
- SSMS (SQL Server Managment Studio)
    
## Dataset description:
- The dataset was downloaded from the WasteDataFlow - Local Authority waste management of United Kingdom. [Download here](http://data.defra.gov.uk/Waste/Q100_data_England_2015_2016.csv) 
- Dataset contains 31 columns and 159931 rows.
- Dataset describes about the data covering waste data and recycling of it on quarterly based from local authorities.

## Exploratory Data Analysis:

### Dataset Load:
- Once the dataset was downloaded in local machine store in your drive
- Open SSMS and connected using Windows Authentication.
- Then created a database 'Datawarehouse'
- by right clicking on 'Datawarehouse' database -> Tasks -> Import Flat File -> Dialogbox opens -> choose the location of dataset saved in local machine to load the dataset.
- Name the table as 'Dataset'
- Preview the data in the dialogbox.
- Modify the columns until the result displays as success without any error.

Before performing any transformation or cleaning make a copy of original data. I copied the dataset into another table 'Datum'.

    select * into Datum from Dataset;

### Data Profiling:
Now the data profiling was done to know the structure of the dataset. 
To view the Overall dataset:
    
    select * from Dataset;
      
To find the Total_rows:
    
    select count(*) as Total_rows from Dataset;

To find the Column name in Dataset:
    
    select name from sys.columns where object_id=OBJECT_ID('Dataset');

To find the Statistical Summary of Dataset:
    
    select
        MIN(TotalTonnes) as min_value,
        MAX(TotalTonnes) as max_value,
        AVG(TotalTonnes) as mean_value,
        STDEVP(TotalTonnes) as stddev_value
    from Dataset;

To find the distinct Count of Authority Column:
    
    select COUNT(DISTINCT Authority) as distinct_values from Dataset;
      

### Data Cleaning:
Remove unnecessary data using drop command:

    alter table Dataset drop column NationalFacilityId, MonthlyComments, MaterialGroup;

Verify the null values in Important Columns from the dataset:
    
    select COUNT(*) as null_values from Dataset where Authority is null;
    select COUNT(*) as null_values from Dataset where TotalTonnes is null;
    select COUNT(*) as null_values from Dataset where Period is null;


## Insights from Dataset are:

### List of Total Authorities:

    select Authority, count(*) as Total_Authority from Dataset Group by Authority having COUNT(*) >1;

This SQL query retrieves the column `Authority` and calculates the total count of occurrences (`Total_Authority`) from the `Dataset` table. It groups the results by `Authority` and filters out groups where the count of occurrences is greater than one (`COUNT(*) > 1`) using the `HAVING` clause. This effectively identifies and displays only those authorities that appear more than once in the dataset, omitting singular occurrences.

### Top 10 “Dry Recyclate” waste Materials processed and the total weight in TotalTonnes for each material quarters:

    select TOP 10 Material, 
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
    from Dataset WHERE OutputProcessType = 'Dry Recyclate' GROUP BY Material ORDER BY SUM(TotalTonnes) DESC;

  This query retrieves the top 10 materials by total tonnes from a dataset where the output process type is 'Dry Recyclate'. It calculates the total tonnes for each material separately for four time periods: April-June, July-September, October-December, and January-March. The results are grouped by material, summing the TotalTonnes for each time period. The query finally orders the materials by their TotalTonnes in descending order and limits the results to the top 10 materials.

### The Lowest 5 authorities & Total Tonnes of waste processed by each of these for six month period and the number of places each authority has moved since previous period

    with RankedAuthorities as ( select Authority, Period, sum(TotalTonnes) as TotalTonnes, row_number() over (partition by Period order by sum(TotalTonnes) asc) as Ranking 
	   from Dataset Group by Authority, Period) select Authority, Period, TotalTonnes, Ranking, 
      case 
        when lag(Ranking) over (partition by Authority order by Period) is null then null
        else Ranking - lag(Ranking) over (partition by Authority order by Period)
      end as Movement 
    from RankedAuthorities where Ranking <= 5 order by Period, Ranking;

  This query calculates and displays the sum of total tonnes from each Authority and Period. Using window functions, Rank each Authority within each period based on Total Tonnes. The calculation movement of each Authority's ranking from the previous period is done using the LAG function. 

The Output would be like:
1. Initial Period (Apr 15 - Jun 15):
    - The rankings are calculated based on the total tonnes for each authority within this period.
    - Movement is NULL because there's no previous period to compare with.
2. Next Period (Jan 16 - Mar 16):
    - Council of the Isles of Scilly and City of London retain their 1st and 2nd positions (Movement=0).
    - Oadby and Wigston Borough Council drops from 5th to 3rd (Movement=-2).
    - Hyndburn Borough Council moves up from 4th to 5th (Movement=1).
    - Eden District Council appears for the first time, so its Movement is NULL

3. Following Period (Jul 15 - Sep 15):
    - Rankings and movements show how the standings have changed.
    - Council of the Isles of Scilly, City of London, West Somerset District Council, and Hyndburn Borough Council maintain their ranks.
    - West Devon Borough Council appears for the first time, so its Movement is NULL.

4. Next Period (Oct 15 - Dec 15):
    - Council of the Isles of Scilly, City of London, and West Somerset District Council retain their ranks.
    - Hyndburn Borough Council drops from 4th to 5th (Movement=-1).
    - Oadby and Wigston Borough Council rises from 5th to 4th (Movement=2).
    
  
### To find each FacilityType that shows the WasteStreamType, TotalTonnesFromHH (households) reported for the period order the output in descending order of TotalTonnesFromHH.

    select distinct([FacilityType]), [WasteStreamType], sum(TonnesFromHHSources) as TotalTonnesfromHH from Dataset where Period is not null group by FacilityType, WasteStreamType
    Order by TotalTonnesfromHH desc;

  This query select unique combinations of FacilityType and WasterStreamType and calculate the sum of TonnesFromHHSources for each combinations. It also includes only the records where the Period is not null. The results are grouped by FacilityType and WasteStreamType. The output is ordered by the TotalTonnes from the household sources in descending order. 


### To find the monthly TotalTonnes processed for each OutputProcessType:

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
			END) AS Jan_Mar_Total from Dataset Group by OutputProcessType, TotalTonnes, Authority, Period order by OutputProcessType, Total_tonnes Desc;


   This query helps to calculate the aggregated metrics for `OutputProcessType` over different periods (`Apr-Jun`, `Jul-Sep`, `Oct-Dec`, `Jan-Mar`). It sums `TotalTonnes` across these periods based on conditions defined in `CASE` statements. The results are grouped by `OutputProcessType`, `Authority`, and `Period`, with sorting by `OutputProcessType` and `Total_tonnes` in descending order.

## How to use: 
To replicate the analysis:
1. Download the dataset from the link mentioned above.
2. Load that dataset into the database in SSMS.
3. Utilise the Query.SQL to find the insights.


### Contact:
For any queries or inquiries, please contact [revathigangadaran@gmail.com].
