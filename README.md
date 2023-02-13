# age_life_support_triage

This README file explains how the coding and data preparation was performed for data corresonding to the paper titled "Age as a prognostic factor for short-term survival in critically ill patients and use in life support allocation under crisis standards of care." This repository also contains several scripts: a quality control script to run on a single institution's data, a script to analyze training data, a script to analyze testing/validation data, and a script converting data from CLIF format into the appropriate format for the remaining scripts. For information on CLIF, see https://github.com/08wparker/Common-Long-ICU-Format.

1. quality_control_check.rmd - performs various quality control checks on the data
2. analysis_test.rmd - performs analysis and generates figures for data from institutions contributing to "training set"
3. analysis_train.rmd - performs analysis and generates figures for data from institutions contributing to "testing set"
4. data_prep.rmd - starts with data in CLIF-like format and format for use in scripts above

## Common Long ICU Format (CLIF)

Data was prepared according to the CLIF standards with a few changes. Race and ethnicity were combined into a single category "race/ethnicity" with levels "Non-Hispanic White", "Non-Hispanic Black", "Hispanic", and "Other". In addition to a standard SOFA score variable, a 48-hour maximum total SOFA score (calculated on a running window from prior 48-hours) was also calculated using data from prior to and including timepoints when the patient was in an ICU. **lfspprt_episode** is an additional variable necessary for this project, but not included in CLIF. See section below on Life Support Episodes. Data in this CLIF-like format is then collapsed to a single row per life support episode using data_prep.rmd, and the variables vent_ever and died are created in the process.

## Sample of prepared data

Below is a sample patient in record prepared after running data_prep.rmd on CLIF-like starting point.

| encounter | patient | lfspprt_episode | sofa_total_48hr | age | sex  |race/ethnicity      | vent_ever | covid | died |
|-----------|---------|-----------------|-----------------|-----|------|--------------------|-----------|-------|------|
| 1         | 1       | 1               | 6               | 75  | male | Non-hispanic White | 0         | 1     |  0   |
| 1         | 1       | 2               | 7               | 75  | male | Non-hispanic White | 0         | 1     |  0   |
| 1         | 1       | 3               | 10              | 75  | male | Non-hispanic White | 0         | 1     |  0   |

Only necessary columns are included in sample above, but the full data may contain all the data variables mentioned above as well as all 48-hour maximum SOFA sub-components.

Together, **encounter**, **patient**, and **lfspprt_episode** uniquely identify a life support episode, as a given patient can have multiple encounters (i.e. hospital admissions), and any given encounter can have multiple life support episodes.

## Life Support Episodes

In looking at Crisis Standards of Care protocols, we wanted to include all patients who would unambiguously need life-support in an ICU during a crisis (inclusion criteria below). During a truly massive crisis, when rationing of critical care is required, some patients who would otherwise be in an ICU may be transferred to general ward floors. To capture the patients who need definitively need life support, we defined life support episodes (LSEs). An LSE is a period of time during which any of the following criteria are met:

1) requiring invasive or non-invasive mechanical ventilation
2) hypoxic respiratory failure with an estimated arterial pressure of oxygen (PaO2) to fraction of inspired oxygen gas (FiO2) ratio less than 200
3) continuous vasoactive drips for shock

Based on how we coded the SOFA sub-scores (see below), this definition includes all patients receiving invasive or non-invasive ventilation, all patients with a respiratory SOFA score > 2, and all patients with a cardiovascular SOFA > 2.

A LSE continues for each hour of a hospitalization during which any of these criteria are fulfilled. The LSE ends after 8 consecutive hours of no criteria being fulfilled, or when the patient dies. (For example, if one of the criteria above is met during hours 1, 2, 3, 4 and hours 7, 8, 9, the LSE would last from hour 1 until hour 17.) LSEs are only based on medical support required, and not location (so a patient's LSE may begin in the ER, for example), though the patient population for this study was limited to patients who were admitted to an ICU at some point during their hospitalization.

## Died variable

The varible **died** is a binary variable indicating whether or not the patient lived or died for the corresponding LSE (since each row represents one LSE). For patients with multiple LSEs, the **died** variable must necessarily be 0 for all LSEs except the final LSE (which may be 0 or 1).

Notes: 
1. Patients whose LSE ended, but later died after being transferred to wards are not considered to have died during their LSE (**died** == 0).
2. Patients who were discharged to hospice from the ICU are considered to have died during their LSE (**died** == 1).

## Vent_ever variable

The variable **vent_ever** is a binary variable indicating whether the patient received invasive or non-invasive ventilation at any point during the LSE.

## SOFA Coding Details

Prior to collapsing data into a single row per LSE, a total SOFA score and component sub-scores were calculated for each hour of a patient's hospitalization using the rules outlined below. Total SOFA score was the sum of the component sub-scores and ranged from 0 to 24.

### General

* Missing values were carried forward from previous observations with no time limit (exceptions: see SOFA respiratory and renal score calculation). For example, if the creatine was 1.5 at 9:00 AM earning a renal Score of 1, the patient's renal sub-score remains 1 until a new creatinine value is recorded.
* If there are no prior values, the SOFA sub-score requiring that value for calculation should be 0 by default.

### Cardiovascular sub-score

Values were assigned based on mean arterial pressure (MAP) and number of pressors (but not pressor dose).

* MAP > 70, no pressors -> 0
* MAP < 70, no pressors -> 1
* Dobutamine alone -> 2
* 1 pressor -> 3
* 2 or more pressors -> 4

Patients were determined to be receiving a medication during a given hour if they were recorded as receiving a non-zero dose of that medication during that hour. They were considered to be receiving this medication until a dose value of 0 was recorded or no dose information was reported for 4 hours.

DOUBLE CHECK THIS NUMBER!

Medications considered vasopressors were epinephrine, norepinephrine, phenylephrine, vasopressin, angiotensin II, dopamine delivered in IV form. Although technically not a vasopressor, dobutamine was also considered as a pressor for coding purposes. Receipt of push dose epinephrine (> 0.5 mg) was not considered receipt of a pressor.

DOUBLE CHEDK THIS NUMBER!

### Respiratory sub-score

Values were based on the PaO2/Fio2 ratio (P/F).
* P/F > 400 -> 0
* 300 < P/F <= 400 -> 1
* 200 < P/F <= 300 and receiving ventilatory support or P/F <= 300 and not receiving ventilatory support ->  2
* 100 < P/F <= 200 and receiving ventilatory support -> 3
* P/F <= 100 and receiving ventilatory support -> 4

If P/F is not available *or is more than 4 hours old*, we used the SaO2/FiO2 ratio (S/F):
* S/F > 400 -> 0
* 315 < S/F <= 400 -> 1
* 235 < S/F <= 315 and receiving ventilatory support or S/F <= 315 and not receiving ventilatory support ->  2
* 150 < S/F <= 235 and receiving ventilatory support -> 3
* S/F <= 150 and receiving ventilatory support -> 4

In other words, P/F ratios were only carried forward for a maximum of 4 hours. This an exception to the rule that missing values should be replaced by previous values carried forward with no time limit. The rationale for this rule is that a P/F ratio (which necessarily comes from an ABG) may not accurately represent a patient's respiratory status 4 or more hours after the ABG was drawn. This may be particularly true among patients whose respiratory status improves (a repeat ABG may not be ordered if it is clinically apparent the patient is doing better).

#### Notes:
* All high-level ICU respiratory support was treated equivalently, i.e. no distinction was made between mechanical ventilation, NIPPV (CPAP/BiPAP), high-flow nasal cannula
* Patients on low-flow nasal cannula could receive at most a respiratory SOFA score of 2 (they are not receiving "high-level ICU respiratory support")
* To estimate the FiO2 for a patient on low-flow nasal cannula, we used the following formula where LPM = liters per minute of low-flow oxygen
      * Fi02 = 0.24 + 0.04*(LPM)
* For patients on room air, we set FiO2 = 0.21.


### Renal sub-score

Values were assigned based only on creatinine (Cr) values.
* Cr <= 1.2 and not on dialysis -> 0
* 1.2 < Cr <= 1.9 and not on dialysis -> 1
* 1.9 < Cr <= 3.4 and not on dialysis -> 2
* 3.4 < Cr <= 4.9 and not on dialysis -> 3
* Cr > 4.9 or on dialysis -> 4

Urine output was ignored because urine output is often inaccurately charted or not charted at all. After receipt of dialysis, the patient's SOFA renal score of 4 was carried forward for 72 hours and no further. After that time, the renal score was based on the most recent creatinine value. This is another exception to the rule that missing values should be replaced by previous values carried forward with no time limit. Coding dialysis receipt in this way means patients who were briefly taken off CVVHD (< 72 hours) were considered "on dialysis" even during the brief hours in between actual receipt of CVVHD. Additionally, patients receiving intermittent dialysis were also considered "on dialysis" in between sessions (for 72 hours).

### Liver sub-score

For total bilirubin (Tbili) measured in mg/dl:
* Tbili <= 1.2 -> 0
* 1.2 < Tbili <= 2.0 -> 1
* 2.0 < Tbili <= 6.0 -> 2
* 6.0 < Tbili <= 12 -> 3
* Tbili > 12 -> 4

### Coagulation sub-score

For platelet count (PLT) in 10^3 per uL:

* PLT > 150 -> 0
* 100 > PLT >= 150 -> 1
* 50 > PLT >= 100 -> 2
* 20 > PLT >= 50 -> 3
* PLT <= 20 -> 4

### Neurologic sub-score

Values assigned by recorded Glascow Coma Scale (GCS). If GCS is missing, a score of zero is assigned.
* GCS 15 ->0
* GCS 13-14 -> 1,
* GCS 10-12 -> 2,
* GCS 6-9 -> 3,
* GCS 0-5 -> 4

### 48-hour Maximum SOFA Score

A 48-hour maximum SOFA score was calculated at each hour of a patient's hospitaliztion using the maximum value of each sub-score in the prior 48-hour window. The maximum value from any two sub-scores may come from different time points in the prior 48-hours (e.g. maximum renal sub-score of 3 from 18 hours prior and maximum cardiovascular sub-score of 2 from 12 hours prior). If there was less than 48 hours of prior data, the maximum value was calculated using the number of hours for which data was available.

A 48-hour maximum SOFA score was used as this is consistent with prior published work (see Raschke et al) and also likely reflects how clinician's would consider SOFA score data in real life (they would probably consider recent historical SOFA data when making decisions rather than the SOFA score at a single specific and arbitrary timepoint).
