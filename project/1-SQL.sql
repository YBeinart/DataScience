
/*************************************************************************                                                                      *
 *            SQL Script for DS COURSE final project FAVORITA            *
 ************************************************************************/     
 
-- ____________________________________________________________
-- STEP 1 - Create database FAVORITA
--          Import 6 data frames from kaggle & create FF
--			Define variables types during import process    
-- ____________________________________________________________

-- Create database FAVORITA;
use FAVORITA;

-- Define variables types during import process


-- ____________________________________________________________
-- STEP 2 - Create "agg_transactions" table to accomodate relevant data for the outcome variable 
--			Create new features YYYYWW (years & weeks) instead of original DATE
--          Create new features weekly_transactions from original feature "transactions"
-- ____________________________________________________________

-- drop table #transactions
SELECT [date]
       ,year(date)*100+datepart(wk,date) as YYYYWW
      ,[store_nbr]
      ,[transactions]
	into #transactions	  
  FROM [FAVORITA].[dbo].[transactions]


select YYYYWW,[store_nbr],sum([transactions]) as weekly_transactions
into agg_transactions
from  #transactions 
group by YYYYWW,store_nbr
order by YYYYWW, store_nbr


-- ____________________________________________________________
--
-- STEP 3 - preliminary EDA to support choosing cluster of stores and family of products  
--  
-- ____________________________________________________________

/***** Script for stores transactions *****/
SELECT (store_nbr), sum(weekly_transactions) as total_transactions   
  FROM [FAVORITA].[dbo].[agg_transactions]
  group by store_nbr
  order by sum(weekly_transactions)

-- drop table #temp_stores

select  a.*, 
		b.weekly_transactions as weekly_transactions 
		
into #temp_stores

from FAVORITA.dbo.agg_transactions as b

left join FAVORITA.dbo.stores as a
	on a.store_nbr = b.store_nbr

select store_nbr, type, cluster, sum(weekly_transactions) as total_transactions
from #temp_stores
group by cluster, type, store_nbr
order by cluster

/****** Script for family of products  ******/
select item_family, count(item_family) as rows_count
from FAVORITA.dbo.FF
group by item_family

SELECT distinct ([family]), count(distinct(item_nbr)) as #_of_items    
  FROM [FAVORITA].[dbo].[items]
  group by family
  order by #_of_items


-- ____________________________________________________________
-- STEP 4 - Create "agg_train_weeks" table to accomodate relevant data for the outcome variable 
--			Create new features YYYYWW (years & weeks) and WW (weeks) instead of original DATE
--          Create two more new features SALES & RETURNS from original feature UNIT_SALES 
--			Refer only to stores from cluster 14 (store_nbr 46,47,48,50)   
-- ____________________________________________________________


---------------Split Purchase and Return Columns-----------------
-- drop table #temp_sales
-- drop table #temp_returns

SELECT year(date)*100+datepart(wk,date) as YYYYWW
	  ,datepart(wk,date) as WW 
      ,[store_nbr]
      ,[item_nbr]
      ,sum ([unit_sales]) as weekly_sales
      ,[onpromotion]
	  into #temp_sales
      FROM [FAVORITA].[dbo].[train]
  where (unit_sales>=0) and (store_nbr=46 or store_nbr=47 or store_nbr=48 or store_nbr=50)
  group by (year(date)*100+datepart(wk,date)),datepart(wk,date),[store_nbr],[item_nbr],[onpromotion]


  SELECT year(date)*100+datepart(wk,date) as YYYYWW
	  ,datepart(wk,date) as WW 
      ,[store_nbr]
      ,[item_nbr]
      ,sum ([unit_sales]) as weekly_returns
      ,[onpromotion]
	  into #temp_returns
      FROM [FAVORITA].[dbo].[train]
  where (unit_sales<0) and (store_nbr=46 or store_nbr=47 or store_nbr=48 or store_nbr=50)
  group by (year(date)*100+datepart(wk,date)),datepart(wk,date),[store_nbr],[item_nbr],[onpromotion]
  

  select a.*, b.weekly_returns
  into agg_train_weeks
  from  #temp_sales as a 
  left join #temp_returns as b
  on a.YYYYWW=b.YYYYWW and a.store_nbr=b.store_nbr and a.item_nbr=b.item_nbr
  group by a.YYYYWW,a.WW, a.store_nbr,a.item_nbr,a.WW, a.onpromotion, a.weekly_sales,b.weekly_returns
  order by a.YYYYWW,a.WW, a.store_nbr,a.item_nbr

/*------------------------check agg_train_weeks-------------------------
SELECT [YYYYWW]
	  ,[WW]
      ,[store_nbr]
      ,[item_nbr]
      ,[weekly_sales]
      ,[onpromotion]
      ,[weekly_returns]
  FROM [FAVORITA].[dbo].[agg_train_weeks]
  order by  [YYYYWW],[WW],[store_nbr],[item_nbr]
------------------------------------------------------------------------*/


-- ____________________________________________________________
-- STEP 5 - Create "agg_oil" table to accomodate relevant data for the outcome variable 
--			Create new features YYYYWW (years & weeks) instead of original DATE
--          Create 3 new features weekly_avg, weekly_max & weekly_min from original feature "dcoilwtico"   
-- ____________________________________________________________
 
-- drop table #oil_temp
SELECT [date]
      ,[dcoilwtico]
	  ,year(date)*100+datepart(wk,date) as YYYYWW
      ,avg(dcoilwtico) over (partition by year(date)*100+datepart(wk,date)) as weekly_avg
	  ,max(dcoilwtico) over (partition by year(date)*100+datepart(wk,date)) as weekly_max
	  ,min(dcoilwtico) over (partition by year(date)*100+datepart(wk,date)) as weekly_min
	  into #oil_temp
  FROM [FAVORITA].[dbo].[oil]

select YYYYWW, 
		weekly_avg, 
		weekly_max, 
		weekly_min
into agg_oil
from  #oil_temp
group by YYYYWW, weekly_avg, weekly_max, weekly_min
order by YYYYWW

alter table agg_oil
alter COLUMN weekly_avg decimal(4,2);


-- ____________________________________________________________
-- STEP 6 - Create "agg_holidays" table to accomodate relevant data for the outcome variable 
--			Create feature YYYYWW (years & weeks) instead of original DATE
--          Create 6 new features (weekly holiday sum per cluster 14 stores locations) from original feature "locale_name" 
--          Create Event_type & Holiday_type features weekly summary   
-- ____________________________________________________________
 


-- drop view holidays
CREATE view holidays AS
SELECT date
    , year(date)*100+datepart(wk,date) as YYYYWW
    , (CASE WHEN (locale_name ='Ecuador' and type = 'Holiday' and transferred = 'False') THEN (1) ELSE (0) END) AS National_Ecuador_weekly_holidays
	, (CASE WHEN (locale_name ='Ecuador' and type = 'Additional' and transferred = 'False') THEN (1) ELSE (0) END) AS National_Ecuador_weekly_additionals
	, (CASE WHEN (locale_name ='Ecuador' and type = 'Event' and transferred = 'False') THEN (1) ELSE (0) END) AS National_Ecuador_weekly_events
	, (CASE WHEN (locale_name ='Ecuador' and type = 'Bridge' and transferred = 'False') THEN (1) ELSE (0) END) AS National_Ecuador_weekly_bridges
	, (CASE WHEN (locale_name ='Ambato' and type = 'Holiday' and transferred = 'False') THEN (1) ELSE (0) END) AS locale_Ambato_weekly_holidays
	, (CASE WHEN (locale_name ='Quito' and type = 'Holiday' and transferred = 'False') THEN (1) ELSE (0) END) AS locale_Quito_weekly_holidays
	, (CASE WHEN (locale_name ='Quito' and type = 'Additional' and transferred = 'False') THEN (1) ELSE (0) END) AS locale_Quito_weekly_additionals
FROM holidays_events;


SELECT [YYYYWW]
      ,sum([National_Ecuador_weekly_holidays])as National_Ecuador_weekly_holidays
      ,sum([National_Ecuador_weekly_additionals])as National_Ecuador_weekly_additionals
      ,sum([National_Ecuador_weekly_events])as National_Ecuador_weekly_events
	  ,sum([National_Ecuador_weekly_bridges])as National_Ecuador_weekly_bridges
	  ,sum([locale_Ambato_weekly_holidays])as locale_Ambato_weekly_holidays
	  ,sum([locale_Quito_weekly_holidays])as locale_Quito_weekly_holidays
	  ,sum([locale_Quito_weekly_additionals])as locale_Quito_weekly_additionals
into agg_holidays
FROM [FAVORITA].[dbo].[holidays]
group by [YYYYWW]
  

-- ____________________________________________________________
--
-- STEP 7 - Create Flat File "FAVORITA.dbo.FF" by Joining tables  
-- ____________________________________________________________


select  a.*, 
		b.family as item_family, b.class as item_class, b.perishable as preishable_item, 
		c.city, c.state, c.type as store_type, c.cluster as store_cluster, 
		d.weekly_transactions,		 
    	e.National_Ecuador_weekly_holidays,	e.National_Ecuador_weekly_additionals, e.National_Ecuador_weekly_events, e.National_Ecuador_weekly_bridges, 
		e.locale_Ambato_weekly_holidays, e.locale_Quito_weekly_holidays, e.locale_Quito_weekly_additionals,
    	f.weekly_avg as oil_weekly_avg, f.weekly_max as oil_weekly_max, f.weekly_min as oil_weekly_min

into FAVORITA.dbo.FF

from FAVORITA.dbo.agg_train_weeks as a

left join FAVORITA.dbo.items as b
	on a.item_nbr = b.item_nbr

left join FAVORITA.dbo.stores as c
	on a.store_nbr = c.store_nbr

left join FAVORITA.dbo.agg_transactions as d
    ON a.store_nbr = d.store_nbr and a.YYYYWW = d.YYYYWW
 
left join [FAVORITA].[dbo].[agg_holidays] as e
    ON a.YYYYWW = e.YYYYWW

left join FAVORITA.dbo.agg_oil as f 
	ON a.YYYYWW = f.YYYYWW


-- ____________________________________________________________
--
-- STEP 8 - Fill with '0' all missing values in attributes at table FF, reflected by weeks with non-holidays & events  
-- ____________________________________________________________

UPDATE FAVORITA.dbo.FF
SET National_Ecuador_weekly_holidays = 0
  , National_Ecuador_weekly_additionals = 0
  , National_Ecuador_weekly_events = 0
  , National_Ecuador_weekly_bridges = 0
  , locale_Ambato_weekly_holidays = 0
  , locale_Quito_weekly_holidays = 0
  , locale_Quito_weekly_additionals = 0
WHERE National_Ecuador_weekly_holidays IS NULL;


-- ____________________________________________________________
--
-- STEP 9 - Narrow Flat File by choosing items from Family SEAFOOD only
--			remove identical features: item_family=SEAFOOD, store_type=A, store_cluster=14
-- ____________________________________________________________

select YYYYWW
      , WW
      , store_nbr
      , item_nbr
	  , item_class
	  , preishable_item
      , weekly_sales
      , weekly_returns
	  , weekly_transactions
      , [onpromotion]
	  , city
	  , [state]
	  , National_Ecuador_weekly_holidays
	  , National_Ecuador_weekly_additionals
      , National_Ecuador_weekly_events
      , National_Ecuador_weekly_bridges
      , locale_Ambato_weekly_holidays
      , locale_Quito_weekly_holidays
      , locale_Quito_weekly_additionals
	  , oil_weekly_avg
	  , oil_weekly_max
	  , oil_weekly_min
into FAVORITA.dbo.FF_seafood_cl_14 /*(stores 46, 47, 48, 50)*/
from FAVORITA.dbo.FF
where item_family like '%SEAFOOD%'



/* select *
from FAVORITA.dbo.FF_seafood_cl_14
order by YYYYWW, store_nbr, item_nbr*/


