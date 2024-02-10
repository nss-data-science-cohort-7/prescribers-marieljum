-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
-- Report the npi and the total number of claims.

SELECT p1.npi, p2.nppes_provider_first_name AS first_name, p2.nppes_provider_last_org_name AS last_name, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 1;
-- Bruce Pendley with 99,707 claims is the highest total (npi 1881634483).

-- 1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, 
-- specialty_description, and the total number of claims.

SELECT p1.npi, p2.nppes_provider_first_name AS first_name, p2.nppes_provider_last_org_name AS last_name, 
	specialty_description AS specialty, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
GROUP BY 1, 2, 3, 4
ORDER BY 5 DESC
LIMIT 1;

-- 2a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT specialty_description AS specialty, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
GROUP BY specialty
ORDER BY total_claims DESC;

-- Family Practice (9752347) followed by Internal Medicine (9,150,489).

-- 2b. Which specialty had the most total number of claims for opioids?

SELECT specialty_description AS specialty, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
LEFT JOIN drug
USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty
ORDER BY total_claims DESC;

-- Nurse Practitioners have the most claims with 900,845. 

-- 2c. Challenge Question: Are there any specialties that appear in the prescriber table that 
-- have no associated prescriptions in the prescription table?

SELECT DISTINCT(specialty)
FROM
(SELECT specialty_description AS specialty, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
GROUP BY specialty)
WHERE total_claims IS NULL;

-------
SELECT specialty_description AS specialty, SUM(total_claim_count) AS total_claims
FROM prescriber
LEFT JOIN prescription
USING(npi)
GROUP BY 1
HAVING SUM(total_claim_count) IS NULL;

-- 15 specialties without associated prescriptions. 

-- 2d. Difficult Bonus: Do not attempt until you have solved all other problems! 
-- For each specialty, report the percentage of total claims by that specialty which are for opioids. 
-- Which specialties have a high percentage of opioids?

WITH claims AS (
	SELECT p1.specialty_description,
		CASE WHEN opioid_drug_flag = 'Y'
				THEN total_claim_count
			ELSE 0 END AS opioid_claims,
		CASE WHEN opioid_drug_flag = 'N'
				THEN total_claim_count
			ELSE 0 END AS non_opioid_claims
	FROM prescriber AS p1
	INNER JOIN prescription AS p2
		ON p1.npi = p2.npi
	INNER JOIN drug AS d
		ON p2.drug_name = d.drug_name
)

SELECT specialty_description,
	SUM(opioid_claims) AS opioid_claims,
	SUM(non_opioid_claims) AS non_opioid_claims,
	ROUND((SUM(opioid_claims * 1.0) / (SUM(opioid_claims) + SUM(non_opioid_claims)) * 100), 2) AS percent_opioid
FROM claims
GROUP BY 1
ORDER BY 4 DESC;


-- 3a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, SUM(total_drug_cost) AS total_cost
FROM prescription
LEFT JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC;

-- Insulin Glargine had the highest total drug cost at $104264066.35.

-- 3b. Which drug (generic_name) has the hightest total cost per day? 
-- Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name, CAST(ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) AS MONEY) as cost_per_day
FROM prescription
LEFT JOIN drug
USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC;

-- C1 Esterase Inhibitor has the highest cost per day at $3495.22.

-- 4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' 
-- which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' 
-- for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.

SELECT 
	drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type
FROM drug;


-- 4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
-- Hint: Format the total costs as MONEY for easier comparision.

SELECT 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
		END AS drug_type,
	CAST(SUM(total_drug_cost) AS MONEY) AS total_cost
FROM prescription
LEFT JOIN drug
USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;

-- More money was spent on opioids (105,080,626.37) than antibiotic (38,435,121.26) - almost three times the cost of antiobiotics. 


-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT state, COUNT(DISTINCT cbsa)
FROM fips_county
LEFT JOIN cbsa
USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;

-- 10 CSBA's in TN. 

-- 5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.


(SELECT cbsaname, cbsa, SUM(population) as population, 'max' AS stats
FROM cbsa
INNER JOIN population 
USING(fipscounty)
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1)
UNION
(SELECT cbsaname, cbsa, SUM(population) as population, 'min' AS stats
FROM cbsa
INNER JOIN population 
USING(fipscounty)
GROUP BY 1, 2
ORDER BY 3 
LIMIT 1)

-- Morristown, TN CSBA has the smallest combined population with 116,352.
-- Nashville-Davidson--Murfreesboro--Franklin, TN CBSA has the largest with 1,830,410.

-- 5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT county, fipscounty, SUM(population) as population
FROM population 
LEFT JOIN cbsa
USING(fipscounty)
LEFT JOIN fips_county
USING(fipscounty)
WHERE cbsa IS NULL
GROUP BY 1, 2
ORDER BY 3 DESC
LIMIT 1;

-- Sevier County is the most populated county (with a population of 95,523) that does not have a CBSA. 


-- 6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
GROUP BY 1, 2
HAVING total_claim_count >= 3000
ORDER BY total_claim_count DESC;

--- 
SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000;

-- Total rows of 507 with "HYDROCODONE-ACETAMINOPHEN" as the drug with most claims at 1,123,360. 

-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, total_claim_count, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Y'
	ELSE 'N'
	END AS opioid
FROM prescription
LEFT JOIN drug
USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

-- 6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT drug_name, SUM(total_claim_count) AS total_claims, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Y'
	END AS opioid,
	nppes_provider_first_name AS dr_first_name, nppes_provider_last_org_name AS dr_last_name
FROM prescription
LEFT JOIN drug
USING(drug_name)
LEFT JOIN prescriber
USING(npi)
GROUP BY drug_name, opioid, dr_first_name, dr_last_name
HAVING SUM(total_claim_count) >= 3000
ORDER BY total_claims DESC;

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and 
-- the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- 7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) 
-- in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
-- Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'


-- 7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
-- You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT npi, drug_name, nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY 1, 2, 3, 4

SELECT npi, drug_name, nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
	

-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
-- Hint - Google the COALESCE function.

SELECT npi, drug_name, nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, 
	COALESCE(total_claim_count, 0) AS total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription
USING(npi, drug_name)
WHERE nppes_provider_city = 'NASHVILLE'
AND specialty_description = 'Pain Management'
AND opioid_drug_flag = 'Y';