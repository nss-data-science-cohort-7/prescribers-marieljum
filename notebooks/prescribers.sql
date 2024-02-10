-- 1a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
-- Report the npi and the total number of claims.

SELECT p1.npi, p2.nppes_provider_first_name AS first_name, p2.nppes_provider_last_org_name AS last_name, SUM(total_claim_count) AS total_claims
FROM prescription AS p1
LEFT JOIN prescriber AS p2
USING(npi)
GROUP BY 1
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

-- Family Practice (9752347) followed by Internal Medicine (9150489).

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

-- 15 specialties without associated prescriptions. 

-- 2d. Difficult Bonus: Do not attempt until you have solved all other problems! 
-- For each specialty, report the percentage of total claims by that specialty which are for opioids. 
-- Which specialties have a high percentage of opioids?

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

SELECT generic_name, ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2) as cost_per_day
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
	SUM(total_drug_cost) AS total_cost
FROM prescription
LEFT JOIN drug
USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;

-- More money was spent on opioids (105,080,626.37) than antibiotic (38,435,121.26) - almost three times the cost of antiobiotics. 


-- 5a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT state, COUNT(cbsa)
FROM fips_county
LEFT JOIN cbsa
USING(fipscounty)
WHERE state = 'TN'
GROUP BY state;

-- 42 CSBA's in TN. 

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

SELECT drug_name, SUM(total_claim_count) AS total_claims
FROM prescription
INNER JOIN drug
USING(drug_name)
GROUP BY drug_name
HAVING SUM(total_claim_count) >= 3000
ORDER BY total_claims DESC;

SELECT drug_name, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY drug_name
HAVING SUM(total_claim_count) >= 3000
ORDER BY total_claims DESC;

-- Total rows of 507 with "HYDROCODONE-ACETAMINOPHEN" as the drug with most claims at 1,123,360. 

-- 6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT drug_name, SUM(total_claim_count) AS total_claims, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'Y'
	END AS opioid
FROM prescription
LEFT JOIN drug
USING(drug_name)
GROUP BY drug_name, opioid
HAVING SUM(total_claim_count) >= 3000
ORDER BY total_claims DESC;

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

SELECT npi, drug_name, specialty_description AS specialty, nppes_provider_city AS provider_city, 
	CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' END AS drug_type
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING(drug_name)
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY 1, 2, 3, 4, 5


SELECT nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name,
	specialty_description AS specialty, nppes_provider_city AS provider_city, 
	CASE WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid' END AS drug_type
FROM prescriber
INNER JOIN drug
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
	AND drug.opioid_drug_flag = 'Y'
GROUP BY 1, 2, 3, 4, 5

SELECT nppes_provider_first_name AS first_name, nppes_provider_last_org_name AS last_name, npi, drug_name,
	specialty_description AS specialty, nppes_provider_city AS provider_city
FROM prescriber
INNER JOIN prescription
USING(npi)
WHERE specialty_description = 'Pain Management' 
	AND nppes_provider_city = 'NASHVILLE'
GROUP BY 1, 2, 3, 4, 5, 6


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

-- 7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
-- Hint - Google the COALESCE function.