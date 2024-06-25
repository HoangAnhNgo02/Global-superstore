with t1 as
(select `Customer ID`
, min(timestampdiff(day, `Order Date`, '2017-01-01')) as recency
, count(distinct `Order ID`)*1.0/abs(timestampdiff(year, '2017-01-01', min(`Order Date`))) as frequency
, sum(Sales) as monetary
from crm_prj.global_superstore gs
group by `Customer ID` ),
t2 as
(select *
, row_number() over (order by `recency`) rn_recency
, row_number() over (order by `frequency`) rn_frequency
, row_number() over (order by `monetary`) rn_monetary
from t1),
t3 as (
select `Customer ID`
,case when `rn_recency` <= 0.25* (select count(distinct `Customer ID`) from t2) then 1
when `rn_recency` <= 0.5*(select count(distinct `Customer ID`) from t2) and `rn_recency` > 0.25*(select count(distinct `Customer ID`) from t2) then 2
when `rn_recency` <= 0.75*(select count(distinct `Customer ID`) from t2) and `rn_recency` > 0.5*(select count(distinct `Customer ID`) from t2) then 3
else 4 end as recency_rank
, case when `rn_frequency` <= 0.25* (select count(distinct `Customer ID`) from t2) then 1
when `rn_frequency` <= 0.5*(select count(distinct `Customer ID`) from t2) and `rn_frequency` > 0.25*(select count(distinct `Customer ID`) from t2) then 2
when `rn_frequency` <= 0.75*(select count(distinct `Customer ID`) from t2) and `rn_frequency` > 0.5*(select count(distinct `Customer ID`) from t2) then 3
else 4 end as frequency_rank
, case when `rn_monetary` <= 0.25* (select count(distinct `Customer ID`) from t2) then 1
when `rn_monetary` <= 0.5*(select count(distinct `Customer ID`) from t2) and `rn_monetary` > 0.25*(select count(distinct `Customer ID`) from t2) then 2
when `rn_monetary` <= 0.75*(select count(distinct `Customer ID`) from t2) and `rn_monetary` > 0.5*(select count(distinct `Customer ID`) from t2) then 3
else 4 end as monetary_rank
from t2
),
t4 as (
select concat(recency_rank, frequency_rank, monetary_rank) RFM
, case when recency_rank + frequency_rank + monetary_rank >= 10 then 'Champions'
when recency_rank >= 3 and frequency_rank >= 3 or monetary_rank >= 3 then 'Promising'
when recency_rank < 3 and frequency_rank + monetary_rank >= 5 then 'Hibernating'
when recency_rank >= 3 and frequency_rank < 3 and monetary_rank < 3 then 'New Customer'
else 'Others'
end as segment
from t3)
select count(RFM)*100.0/(select count(RFM) from t4) proportion
, count(RFM) num_cus
, segment
from t4
group by segment
order by num_cus desc;
