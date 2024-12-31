Select * from insurance.policies
limit 10;

Set sql_safe_updates=1;

## Correcting column name from Mark to Make
Alter table insurance.policies
Rename column Mark to Make;

Delete from insurance.claims
where claimid=2034;

## Finding policy with more than 1 claims
Select policyid from insurance.claims
group by policyid
having count(claimid)>1;


## Task 2
with top_brands as
(
Select p.make, count(c.claimid) as ct_claim
from insurance.policies p
join insurance.claims c
on p.policyid=c.policyid
where c.claimtype='Glass'
group by make
order by ct_claim desc
limit 5
)

Select p.make,round(avg(p.premium)) as Avg_Premium, round(avg(c.IncurredAmount)) as Avg_IncAmt
from top_brands t
join insurance.policies p
on t.make=p.make
join insurance.claims c
on p.policyid=c.policyid
where claimtype='Glass'
group by t.make;

##Task 3
with cte as
(
Select claimid,policyid,IncurredAmount,
ROW_NUMBER() OVER (PARTITION BY policyid order by claimid) as rnk
from insurance.claims
where policyid IN(Select policyid from insurance.claims
group by policyid
having count(claimid)>1)
)

Select cte.policyid,
	AVG(CASE WHEN rnk=1 then cte.IncurredAmount END) as first_claim,
    AVG(CASE WHEN rnk=2 then cte.IncurredAmount END) as second_claim
from cte
where rnk IN(1,2)
group by policyid;



####						1.Portfolio Dashboard					####

## Calculate Profit
WITH PolicyPremiums AS (
    SELECT 
        year, 
        ROUND(SUM(p.premium), 2) AS total_premium
    FROM insurance.policies p
    GROUP BY year
    ORDER BY year ASC
),
PolicyClaims AS (
    SELECT 
        p.year, 
        ROUND(SUM(c.IncurredAmount), 2) AS total_claims
    FROM insurance.policies p
    left JOIN insurance.claims c ON p.policyid = c.policyid
    GROUP BY p.year
    ORDER BY p.year ASC
)
SELECT 
    pp.year,
    pp.total_premium,
    pc.total_claims,
    round(pp.total_premium-pc.total_claims,0) as profit
FROM PolicyPremiums pp
LEFT JOIN PolicyClaims pc ON pp.year = pc.year
ORDER BY pp.year ASC;


##Single query for dashboard except for profit
Select p.year, p.premium,
make,p.suminsured,p.policyid,p.RenewalIndicator,c.IncurredAmount
from insurance.claims c
right join insurance.policies p
on c.policyid=p.policyid
order by year, policyid asc;


###						3.Profitability by engine type							###

##Single query for dashboard
Select p.year, p.EngineType, c.claimid,p.premium, c.IncurredAmount,p.vehicleage, p.VehicleFirstRegistrationYear,
p.make,p.Vehicletype,p.vehicleusage,p.leasing,
(Case when p.RenewalIndicator=1 then 1 else 0 end) as Total_Renewal,
(Case when p.RenewalIndicator=0 then 1 else 0 end) as Total_Cancel
from insurance.policies p
left join insurance.claims c
on p.policyid=c.policyid
order by year asc;


			 
###						4.Trend in claims							###

##Single query for dashboard

Select year,p.policyid, p.vehicleage,p.VehicleFirstRegistrationYear,p.EngineType,p.make,p.Vehicletype,p.leasing,p.VehicleUsage,c.claimid
from insurance.claims c
left join insurance.policies p
on c.policyid=p.policyid
order by 1;

###						5.Trends in Sales  							###

##Single query for dashboard
with cte as
(
Select p.year,p.policyid,p.make,
CASE when p.Leasing = 1 then 'Leasing' else 'Private' end as property_type,
CASE when p.RenewalIndicator = 1 then 'Renewed' else 'Canceled' end as Renewal_status,
p.vehicleage,p.enginetype,p.premium,sum(c.IncurredAmount) as Inc_Amt
from insurance.policies p
left join insurance.claims c
on p.policyid=c.policyid
group by 1,2,3,4,5,6,7,8
order by year,policyid)

Select count(policyid) from cte;

####Rough 
Select count(policyid) from insurance.policies;

with cte as
(
Select p.year, round(p.premium,0),
make,p.suminsured,p.policyid,p.RenewalIndicator,sum(c.IncurredAmount) as Amt_paid
from insurance.claims c
right join insurance.policies p
on c.policyid=p.policyid
group by p.year,p.premium,make,suminsured,policyid,renewalindicator
order by year, policyid asc)

Select sum(Amt_paid) from cte;

Select sum(IncurredAmount) from insurance.claims;




##NOTE
#Policyid 7220 is missing from policies table