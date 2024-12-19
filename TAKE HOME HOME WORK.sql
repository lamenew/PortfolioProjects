--WITH DEATHIDENTIFY AS (
--SELECT DATEDIFF(year, PAT.BIRTHDATE, GETDATE()) AS PATIENT_AGE ,PAT.DEATHDATE FROM [dbo].[patients] PAT)
--SELECT * FROM DEATHIDENTIFY
--WHERE PATIENT_AGE BETWEEN 18 and 36 AND DEATHDATE <> 'NA';



---Part 1: Assemble the project cohort

with cohort AS (
SELECT  MED.START MedicationsStart,MED.STOP MedicationsStop ,MED.ENCOUNTER,MED.DESCRIPTION MedicationsDescription, DATEDIFF(year, PAT.BIRTHDATE, GETDATE()) AS PATIENT_AGE,
PAT.DEATHDATE, cast(ENCR.START as datetime)  EncounterStart, cast(ENCR.STOP as datetime) EncounterStop,ENCR.Id,MED.CODE
 FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		) 
		SELECT * FROM cohort WHERE 
		(PATIENT_AGE BETWEEN 18 and 36) AND DEATHDATE <> 'NA' 
		ORDER BY ENCOUNTER;

--Part 2: Create additional fields		

--DEATH_AT_VISIT_IND: 1 if patient died during the drug overdose encounter, 0 if the patient died at a different time

with cohort AS (
SELECT  MED.START MedicationsStart,MED.STOP MedicationsStop ,MED.ENCOUNTER,MED.DESCRIPTION MedicationsDescription, DATEDIFF(year, PAT.BIRTHDATE, GETDATE()) AS PATIENT_AGE,
PAT.DEATHDATE, cast(ENCR.START as datetime)  EncounterStart, cast(ENCR.STOP as datetime) EncounterStop,ENCR.Id,MED.CODE
 FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		) 
		SELECT CASE WHEN CAST(DEATHDATE AS DATE) = CAST(EncounterStart AS DATE) THEN 1 ELSE 0 END AS DEATH_AT_VISIT_IND 
		FROM cohort 
		WHERE 	(PATIENT_AGE BETWEEN 18 and 36) AND DEATHDATE <> 'NA' 
		ORDER BY ENCOUNTER;





-- COUNT_CURRENT_MEDS Count of active medications at the start of the drug overdose encounter

with cohort AS (
SELECT  MED.START MedicationsStart,MED.STOP MedicationsStop ,MED.ENCOUNTER,MED.DESCRIPTION MedicationsDescription, DATEDIFF(year, PAT.BIRTHDATE, GETDATE()) AS PATIENT_AGE,
PAT.DEATHDATE, cast(ENCR.START as datetime)  EncounterStart, cast(ENCR.STOP as datetime) EncounterStop,ENCR.Id,MED.CODE
 FROM  [dbo].[medications] MED
LEFT JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
LEFT JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		) 
		SELECT Id, COUNT(CODE) AS COUNT_CURRENT_MEDS FROM cohort WHERE 
		(PATIENT_AGE BETWEEN 18 and 36) AND DEATHDATE <> 'NA' 
		AND MedicationsStart <= EncounterStart AND (MedicationsStop  IS NULL OR MedicationsStop >= EncounterStart) AND MedicationsStop <> 'NA'
		GROUP BY ID

		
		

SELECT ENCR.Id, COUNT(MED.CODE) AS COUNT_CURRENT_MEDS
FROM [dbo].[encounters] ENCR 
LEFT JOIN [dbo].[medications] MED  ON ENCR.PATIENT = MED.PATIENT 
AND MED.START <= ENCR.START AND (MED.Stop IS NULL OR MED.Stop >= ENCR.Start) AND MED.Stop <> 'NA'
GROUP BY ENCR.Id

-- CURRENT_OPIOID_IND: 1 if the patient had at least one active medication at the start of the overdose encounter that is on the Opioids List (provided below), 0 if not

with cohort AS (
SELECT  MED.START MedicationsStart,MED.STOP MedicationsStop ,MED.ENCOUNTER,MED.DESCRIPTION MedicationsDescription, DATEDIFF(year, PAT.BIRTHDATE, GETDATE()) AS PATIENT_AGE,
PAT.DEATHDATE, cast(ENCR.START as datetime)  EncounterStart, cast(ENCR.STOP as datetime) EncounterStop
 FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		) 
		SELECT * FROM cohort WHERE 
		(PATIENT_AGE BETWEEN 18 and 36) AND DEATHDATE <> 'NA' 
		ORDER BY ENCOUNTER;


--CURRENT_OPIOID_IND: 1 if the patient had at least one active medication at the start of the overdose encounter that is on the Opioids List (provided below), 0 if not

SELECT   ID, CASE WHEN EXISTS
( SELECT MED.CODE
FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		AND MED.START <= ENCR.START AND (MED.Stop IS NULL OR MED.Stop >= ENCR.Start) AND MED.Stop <> 'NA'
		) THEN 1 ELSE 0 END AS CURRENT_OPIOID_IND
		FROM [dbo].[encounters];



SELECT   ID, CASE WHEN EXISTS
( SELECT MED.CODE
FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		AND MED.START = ENCR.START AND (MED.Stop IS NULL OR MED.Stop >= ENCR.Start AND ENCR.STOP <= DATEADD(DAY,90,ENCR.STOP)) AND MED.Stop <> 'NA'
		) THEN 1 ELSE 0 END AS READMISSION_90_DAY_IND
		FROM [dbo].[encounters];

--READMISSION_90_DAY_IND: 1 if the visit resulted in a subsequent drug overdose readmission within 90 days, 0 if not
SELECT   ID, CASE WHEN EXISTS
( SELECT MED.CODE
FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		AND MED.START = ENCR.START AND (MED.Stop IS NULL OR MED.Stop >= ENCR.Start AND ENCR.STOP <= DATEADD(DAY,30,ENCR.STOP)) AND MED.Stop <> 'NA'
		) THEN 1 ELSE 0 END AS READMISSION_90_DAY_IND
		FROM [dbo].[encounters];



--READMISSION_30_DAY_IND: 1 if the visit resulted in a subsequent drug overdose readmission within 30 days, 0 if not overdose encounter, 0 if not

SELECT   ID, CASE WHEN EXISTS
( SELECT MED.CODE
FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		AND MED.START = ENCR.START AND (MED.Stop IS NULL OR MED.Stop >= ENCR.Start AND ENCR.STOP <= DATEADD(DAY,30,ENCR.STOP)) AND MED.Stop <> 'NA'
		) THEN 1 ELSE 0 END AS READMISSION_30_DAY_IND
		FROM [dbo].[encounters];



--FIRST_READMISSION_DATE: The date of the index visit's first readmission for drug overdose. Field should be left as N/A if no readmission for drug overdose within 90 days

with cohort AS (
SELECT  MED.START MedicationsStart,MED.STOP MedicationsStop ,MED.ENCOUNTER,MED.DESCRIPTION MedicationsDescription, DATEDIFF(year, PAT.BIRTHDATE, GETDATE()) AS PATIENT_AGE,
PAT.DEATHDATE, cast(ENCR.START as datetime)  EncounterStart, cast(ENCR.STOP as datetime) EncounterStop,ENCR.Id
 FROM  [dbo].[medications] MED
INNER JOIN [dbo].[patients] PAT on PAT.ID=MED.PATIENT
INNER JOIN [dbo].[encounters] ENCR ON  ENCR.PATIENT=MED.PATIENT
WHERE (MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%' or 
        MED.DESCRIPTION LIKE '%Fentanyl%' or
		MED.DESCRIPTION LIKE '%Oxycodone-acetaminophen%') AND MED.START >'1999-07-15'
		) 
		SELECT ID, CASE   WHEN  EncounterStart IS NOT NULL THEN MIN(EncounterStart) ELSE 'NA' END AS FIRST_READMISSION_DATE
		FROM  COHORT
		GROUP BY ID,EncounterStart

		
