# ESPEN MDA XLSForms — full reference dump

Generated from `forms/espen mda/*.xlsx` (survey + choices + settings sheets) on 2026-07-05.
Supporting reference for `2026-07-05-espen-mda-questionnaires.md` — the implementation
plan cites linkIds and labels from this dump. Regenerate with the script in the plan's Task 0.


## demo_mda_9999_1_location.xlsx

**settings:** `form_title`=(Demo) 1. MDA Location Form V3; `form_id`=demo_mda_9999_1_location_v3; `default_language`=English; `allow_choice_duplicates`=yes

### survey

| type | name | label | hint | relevant | calculation | constraint | constraint_message | required | appearance | choice_filter | default | read_only |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| select_one recorder_id | l_recorder_id | Select the recorder ID |  |  |  |  |  |  |  |  |  |  |
| select_one state | l_state | Select State / Region / Province |  |  |  |  |  | yes |  |  |  |  |
| select_one district | l_district | Select District / LGA / County |  |  |  |  |  | yes |  | state = ${l_state} |  |  |
| select_one health_facility | l_health_facility | Enter the Health facility / Sub district |  |  |  |  |  | yes |  | district = ${l_district} |  |  |
| select_one location | l_location | Enter the village / location / site |  |  |  |  |  | yes |  | health_facility = ${l_health_facility} |  |  |
| select_one location_id | l_location_id | Enter the ID of village / location / site |  |  |  |  |  | yes |  | location = ${l_location} |  |  |
| int | l_total_pop | Enter the total population of the village |  |  |  |  |  | yes |  |  |  |  |
| int | I_total_popn_1_4 | Total number of people aged 1-4 years of the village |  |  |  |  |  | yes |  |  |  |  |
| int | I_total_popn_5_14 | Total number of people aged 5-14 years of the Village |  |  |  |  |  | yes |  |  |  |  |
| int | I_total_popn_15_More | Total number of people aged 15 years and above in the village |  |  |  |  |  | yes |  |  |  |  |
| calculate | l_eligible_pop | Total eligible population of the village |  |  | ${I_total_popn_1_4} + ${I_total_popn_5_14} + ${I_total_popn_15_More} |  |  |  |  |  |  |  |
| geopoint | l_gps | GPS of the village |  |  |  |  |  | yes | maps |  |  |  |
| string | l_submitting_report | Enter name of person submitting report |  |  |  |  |  | yes |  |  |  |  |
| text | l_additional_note | Any other information |  |  |  |  |  | no |  |  |  |  |
| start | l_start |  |  |  |  |  |  |  |  |  |  |  |
| end | l_end |  |  |  |  |  |  |  |  |  |  |  |

### choices

| list_name | name | label::English | state | district | health_facility | location |
|---|---|---|---|---|---|---|
| recorder_id | 01 | 01 |  |  |  |  |
| recorder_id | 02 | 02 |  |  |  |  |
| recorder_id | 03 | 03 |  |  |  |  |
| recorder_id | 04 | 04 |  |  |  |  |
| recorder_id | 05 | 05 |  |  |  |  |
| recorder_id | 06 | 06 |  |  |  |  |
| recorder_id | 07 | 07 |  |  |  |  |
| recorder_id | 08 | 08 |  |  |  |  |
| recorder_id | 09 | 09 |  |  |  |  |
| recorder_id | 10 | 10 |  |  |  |  |
| recorder_id | 11 | 11 |  |  |  |  |
| recorder_id | 12 | 12 |  |  |  |  |
| recorder_id | 99 | 99 |  |  |  |  |
| state | Bandundu | Bandundu |  |  |  |  |
| state | Bas-Congo | Bas-Congo |  |  |  |  |
| state | Haut-Katanga | Haut-Katanga |  |  |  |  |
| state | Ituri | Ituri |  |  |  |  |
| state | Kasai-Central | Kasai-Central |  |  |  |  |
| state | Kasai-Oriental | Kasai-Oriental |  |  |  |  |
| state | Kwango | Kwango |  |  |  |  |
| state | Lualaba | Lualaba |  |  |  |  |
| state | Nord-Kivu | Nord-Kivu |  |  |  |  |
| state | Sud-Kivu | Sud-Kivu |  |  |  |  |
| district | Bagata | Bagata | Bandundu |  |  |  |
| district | Bulungu | Bulungu | Bandundu |  |  |  |
| district | Boma | Boma | Bas-Congo |  |  |  |
| district | Matadi | Matadi | Bas-Congo |  |  |  |
| district | Kambove | Kambove | Haut-Katanga |  |  |  |
| district | Kipushi | Kipushi | Haut-Katanga |  |  |  |
| district | Bunia | Bunia | Ituri |  |  |  |
| district | Mambasa | Mambasa | Ituri |  |  |  |
| district | Dibaya | Dibaya | Kasai-Central |  |  |  |
| district | Kazumba | Kazumba | Kasai-Central |  |  |  |
| district | Lupatapata | Lupatapata | Kasai-Oriental |  |  |  |
| district | Miabi | Miabi | Kasai-Oriental |  |  |  |
| district | Kenge | Kenge | Kwango |  |  |  |
| district | Popokabaka | Popokabaka | Kwango |  |  |  |
| district | Fungurume | Fungurume | Lualaba |  |  |  |
| district | Kolwezi | Kolwezi | Lualaba |  |  |  |
| district | Beni | Beni | Nord-Kivu |  |  |  |
| district | Rutshuru | Rutshuru | Nord-Kivu |  |  |  |
| district | Kalehe | Kalehe | Sud-Kivu |  |  |  |
| district | Uvira | Uvira | Sud-Kivu |  |  |  |
| health_facility | Kikongo Centre | Kikongo Centre |  | Bagata |  |  |
| health_facility | Oicha Centre | Oicha Centre |  | Beni |  |  |
| health_facility | Nzadi Centre | Nzadi Centre |  | Boma |  |  |
| health_facility | Niadi Centre | Niadi Centre |  | Bulungu |  |  |
| health_facility | Mudzipela Centre | Mudzipela Centre |  | Bunia |  |  |
| health_facility | Tshikapa Centre | Tshikapa Centre |  | Dibaya |  |  |
| health_facility | Tenke Centre | Tenke Centre |  | Fungurume |  |  |
| health_facility | Ihusi Centre | Ihusi Centre |  | Kalehe |  |  |
| health_facility | Kakanda Centre | Kakanda Centre |  | Kambove |  |  |
| health_facility | Musese | Musese |  | Kazumba |  |  |
| health_facility | Bukanga | Bukanga |  | Kenge |  |  |
| health_facility | Lumata Centre | Lumata Centre |  | Kipushi |  |  |
| health_facility | Dilala Centre | Dilala Centre |  | Kolwezi |  |  |
| health_facility | Mulenda | Mulenda |  | Lupatapata |  |  |
| health_facility | Makeke Centre | Makeke Centre |  | Mambasa |  |  |
| health_facility | Kinkanda Centre | Kinkanda Centre |  | Matadi |  |  |
| health_facility | Katende Centre | Katende Centre |  | Miabi |  |  |
| health_facility | Yasa Bonga | Yasa Bonga |  | Popokabaka |  |  |
| health_facility | Kiwanja Centre | Kiwanja Centre |  | Rutshuru |  |  |
| health_facility | Kavimvira Centre | Kavimvira Centre |  | Uvira |  |  |
| location | Misangi | Misangi |  |  | Bukanga |  |
| location | Mutoshi | Mutoshi |  |  | Dilala Centre |  |
| location | Nyabibwe | Nyabibwe |  |  | Ihusi Centre |  |
| location | Mwadingusha | Mwadingusha |  |  | Kakanda Centre |  |
| location | Kalelu | Kalelu |  |  | Katende Centre |  |
| location | Sange | Sange |  |  | Kavimvira Centre |  |
| location | Kimputu | Kimputu |  |  | Kikongo Centre |  |
| location | Soyo | Soyo |  |  | Kinkanda Centre |  |
| location | Bwito | Bwito |  |  | Kiwanja Centre |  |
| location | Kafubu | Kafubu |  |  | Lumata Centre |  |
| location | Biakato | Biakato |  |  | Makeke Centre |  |
| location | Hoho | Hoho |  |  | Mudzipela Centre |  |
| location | Mbujimayi Rural | Mbujimayi Rural |  |  | Mulenda |  |
| location | Lubudi | Lubudi |  |  | Musese |  |
| location | Kiyaka | Kiyaka |  |  | Niadi Centre |  |
| location | Lovo | Lovo |  |  | Nzadi Centre |  |
| location | Mavivi | Mavivi |  |  | Oicha Centre |  |
| location | Kando | Kando |  |  | Tenke Centre |  |
| location | Kabondo | Kabondo |  |  | Tshikapa Centre |  |
| location | Kipata | Kipata |  |  | Yasa Bonga |  |
| location_id | 101 | 101 |  |  |  | Kabondo |
| location_id | 102 | 102 |  |  |  | Lubudi |
| location_id | 103 | 103 |  |  |  | Kalelu |
| location_id | 104 | 104 |  |  |  | Mbujimayi Rural |
| location_id | 105 | 105 |  |  |  | Misangi |
| location_id | 106 | 106 |  |  |  | Kipata |
| location_id | 107 | 107 |  |  |  | Kimputu |
| location_id | 108 | 108 |  |  |  | Kiyaka |
| location_id | 109 | 109 |  |  |  | Soyo |
| location_id | 110 | 110 |  |  |  | Lovo |
| location_id | 111 | 111 |  |  |  | Kafubu |
| location_id | 112 | 112 |  |  |  | Mwadingusha |
| location_id | 113 | 113 |  |  |  | Hoho |
| location_id | 114 | 114 |  |  |  | Biakato |
| location_id | 115 | 115 |  |  |  | Mavivi |
| location_id | 116 | 116 |  |  |  | Bwito |
| location_id | 117 | 117 |  |  |  | Sange |
| location_id | 118 | 118 |  |  |  | Nyabibwe |
| location_id | 119 | 119 |  |  |  | Mutoshi |
| location_id | 120 | 120 |  |  |  | Kando |

## demo_mda_9999_2_part.xlsx

**settings:** `form_title`=(Demo) 2. MDA Medicine Receipt Form V3; `form_id`=demo_mda_9999_2_part_v3; `default_language`=English

### survey

| type | name | label | hint | relevant | calculation | constraint | constraint_message | required | appearance | choice_filter | default | read_only |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| select_one recorder_id | p_recorder_id | Select the recorder ID |  |  |  |  |  |  |  |  |  |  |
| string | p_state | Select State / Region / Province |  |  |  |  |  | yes |  |  |  |  |
| string | p_district | Select District / LGA / County |  |  |  |  |  | yes |  |  |  |  |
| string | p_health_facility | Enter the Health facility / Sub district |  |  |  |  |  | yes |  |  |  |  |
| select_multiple disease | p_disease | Disease covered by the MDA |  |  |  |  |  | yes |  |  |  |  |
| select_multiple medicine | p_medicine | Select the medicine package |  |  |  | not(   selected(${p_disease}, 'LF') and   selected(${p_disease}, 'ONCHO') and   selected(${p_medicine}, 'IVM') ) and not(   selected(${p_disease}, 'STH') and   selected(${p_disease}, 'SCHISTO') and   (     selected(${p_medicine}, 'ALB') or     selected(${p_medicine}, 'MEB') or     selected(${p_medicine}, 'PZQ')   ) ) and not(   selected(${p_disease}, 'SCHISTO') and   not(selected(${p_disease}, 'STH')) and   (     selected(${p_medicine}, 'PZQ+ALB') or     selected(${p_medicine}, 'PZQ+MEB')   ) ) and not(selected(${p_medicine}, 'IVM') and not(selected(${p_disease}, 'ONCHO') and not(selected(${p_disease}, 'LF')))) and not(selected(${p_medicine}, 'IVM+ALB') and not(selected(${p_disease}, 'LF') or selected(${p_disease}, 'ONCHO'))) and not(selected(${p_medicine}, 'IVM+ALB+DEC') and not(selected(${p_disease}, 'LF'))) and not(selected(${p_medicine}, 'ALB') and not(selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'MEB') and not(selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'PZQ') and not(selected(${p_disease}, 'SCHISTO'))) and not(selected(${p_medicine}, 'PZQ+ALB') and not(selected(${p_disease}, 'SCHISTO') or selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'PZQ+MEB') and not(selected(${p_disease}, 'SCHISTO') or selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'AZM.TAB') and not(selected(${p_disease}, 'TRACHOMA'))) and not(selected(${p_medicine}, 'AZM.SUSP') and not(selected(${p_disease}, 'TRACHOMA'))) and not(selected(${p_medicine}, 'TETRA') and not(selected(${p_disease}, 'TRACHOMA'))) | You cannot select a single medicine together with its combination version | yes |  |  selected(${p_disease}, disease_filter) |  |  |
| integer | p_total_pzq | Total Praziquantel received |  | selected(${p_medicine}, 'PZQ') or selected(${p_medicine}, 'PZQ+ALB') or selected(${p_medicine}, 'PZQ+MEB') |  |  |  | yes |  |  |  |  |
| integer | p_total_alb | Total Albendazole received |  | selected(${p_medicine}, 'ALB') or selected(${p_medicine}, 'IVM+ALB')  or selected(${p_medicine}, 'IVM+ALB+DEC') or selected(${p_medicine}, 'PZQ+ALB') |  |  |  | yes |  |  |  |  |
| integer | p_total_meb | Total Mebendazole received |  | selected(${p_medicine}, 'MEB') or selected(${p_medicine}, 'PZQ+MEB') |  |  |  | yes |  |  |  |  |
| integer | p_total_ivm | Total Ivermectin received |  | selected(${p_medicine}, 'IVM') or selected(${p_medicine}, 'IVM+ALB')  or selected(${p_medicine}, 'IVM+ALB+DEC') |  |  |  | yes |  |  |  |  |
| integer | p_total_dec | Total Diethylcarbamazine received |  | selected(${p_medicine}, 'IVM+ALB+DEC') |  |  |  | yes |  |  |  |  |
| integer | p_total_az_sus | Total Azithromycin suspension (in l) received |  | selected(${p_medicine}, 'AZM.SUSP') |  |  |  | yes |  |  |  |  |
| integer | p_total_az_tab | Total Azithromycin tablets received |  | selected(${p_medicine}, 'AZM.TAB') |  |  |  | yes |  |  |  |  |
| integer | p_total_tetra | Total Tetracycline received |  | selected(${p_medicine}, 'TETRA') |  |  |  | yes |  |  |  |  |
| text | p_add_note | Additional Note |  |  |  |  |  | no |  |  |  |  |
| start | p_start |  |  |  |  |  |  |  |  |  |  |  |
| end | p_end |  |  |  |  |  |  |  |  |  |  |  |

### choices

| list_name | name | label::English | disease_filter |
|---|---|---|---|
| recorder_id | 01 | 01 |  |
| recorder_id | 02 | 02 |  |
| recorder_id | 03 | 03 |  |
| recorder_id | 04 | 04 |  |
| recorder_id | 05 | 05 |  |
| recorder_id | 06 | 06 |  |
| recorder_id | 07 | 07 |  |
| recorder_id | 08 | 08 |  |
| recorder_id | 09 | 09 |  |
| recorder_id | 10 | 10 |  |
| recorder_id | 11 | 11 |  |
| recorder_id | 12 | 12 |  |
| recorder_id | 99 | 99 |  |
| yes_no | Yes | Yes |  |
| yes_no | No | No |  |
| disease | LF | LF |  |
| disease | ONCHO | ONCHO |  |
| disease | SCHISTO | SCHISTO |  |
| disease | STH | STH |  |
| disease | TRACHOMA | TRACHOMA |  |
| medicine | IVM | IVM | ONCHO |
| medicine | IVM+ALB | IVM+ALB | LF |
| medicine | IVM+ALB+DEC | IVM+ALB+DEC | LF |
| medicine | ALB | ALB | STH |
| medicine | TETRA | TETRA | TRACHOMA |
| medicine | AZM.TAB | AZM TAB | TRACHOMA |
| medicine | AZM.SUSP | AZM SUSP | TRACHOMA |
| medicine | MEB | MEB | STH |
| medicine | PZQ | PZQ | SCHISTO |
| medicine | PZQ+ALB | PZQ+ALB | SCHISTO |
| medicine | PZQ+MEB | PZQ+MEB | SCHISTO |

## demo_mda_9999_3_med_treatment.xlsx

**settings:** `form_title`=(Demo) 3. MDA Medicine Treatement Form V3; `form_id`=demo_mda_9999_3_med_treatement_v3; `default_language`=English

### survey

| type | name | label | hint | relevant | calculation | constraint | constraint_message | required | appearance | choice_filter | default | read_only |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| select_one recorder_id | p_recorder_id | Select the recorder ID |  |  |  |  |  |  |  |  |  |  |
| string | p_state | Select State / Region / Province |  |  |  |  |  | yes |  |  |  |  |
| string | p_district | Select District / LGA / County |  |  |  |  |  | yes |  |  |  |  |
| string | p_health_facility | Select the Health facility / Sub district |  |  |  |  |  | yes |  |  |  |  |
| string | p_location | Enter the village / location / site |  |  |  |  |  | yes |  |  |  |  |
| string | p_location_id | Enter the ID of village / location / site |  |  |  |  |  | yes |  |  |  |  |
| select_one campaign_day | p_campaign_day | Day of the campaign |  |  |  |  |  | yes |  |  |  |  |
| select_multiple disease | p_disease | Disease covered by the TDM? |  |  |  |  |  | yes |  |  |  |  |
| select_multiple medicine | p_medicine | Select the medicine package |  |  |  |  |  | yes |  |  selected(${p_disease}, disease_filter) |  |  |
| begin group | census | Population census |  |  |  |  |  |  |  |  |  |  |
| select_one census_method | census_method | Cencus method |  |  |  |  |  | Yes |  |  |  |  |
| integer | census_house_hold | Number of households |  |  |  |  |  |  |  |  |  |  |
| integer | census_men | Number of men |  |  |  |  |  |  |  |  |  |  |
| integer | census_women | Number of women |  |  |  |  |  |  |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | dec_by_sex | DEC By sex |  | selected(${p_medicine}, 'IVM+ALB+DEC')  |  |  |  |  |  |  |  |  |
| integer | dec_5_14_female_treated | 5-14 years old treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_5_14_male_treated | 5-14 years old treated Male |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_15_female_treated | 15 years and over treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_15_male_treated | 15 years and over treated Male |  |  |  |  |  | yes |  |  |  |  |
| calculate | dec_men_treated | Men treated |  |  | ${dec_5_14_male_treated} + ${dec_15_male_treated} |  |  |  |  |  |  |  |
| calculate | dec_women_treated | Women treated |  |  | ${dec_5_14_female_treated} + ${dec_15_male_treated} |  |  |  |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | dec_reason_not_treated | Reasons not treated with DEC |  | selected(${p_medicine}, 'IVM+ALB+DEC')  |  |  |  |  |  |  |  |  |
| integer | dec_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | dec_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | alb_by_sex | ALB By sex |  | selected(${p_medicine}, 'IVM+ALB+DEC') or selected(${p_medicine}, 'IVM+ALB') or selected(${p_medicine}, 'ALB') or selected(${p_medicine}, 'PZQ+ALB')  |  |  |  |  |  |  |  |  |
| integer | alb_5_14_female_treated | 5-14 years old treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_5_14_male_treated | 5-14 years old treated Male |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_15_female_treated | 15 years and over treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_15_male_treated | 15 years and over treated Male |  |  |  |  |  | yes |  |  |  |  |
| calculate | alb_men_treated | Men treated |  |  | ${alb_5_14_male_treated} + ${alb_15_male_treated} |  |  |  |  |  |  |  |
| calculate | alb_women_treated | Women treated |  |  | ${alb_5_14_female_treated} + ${alb_15_male_treated} |  |  |  |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | alb_reason_not_treated | Reasons not treated with ALB |  | selected(${p_medicine}, 'IVM+ALB+DEC') or selected(${p_medicine}, 'IVM+ALB') or selected(${p_medicine}, 'ALB') or selected(${p_medicine}, 'PZQ+ALB')  |  |  |  |  |  |  |  |  |
| integer | alb_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | alb_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | meb_by_sex | MBD By sex |  | selected(${p_medicine}, 'PZQ+MEB') or selected(${p_medicine}, 'MEB')  |  |  |  |  |  |  |  |  |
| integer | meb_5_14_female_treated | 5-14 years old treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_5_14_male_treated | 5-14 years old treated Male |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_15_female_treated | 15 years and over treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_15_male_treated | 15 years and over treated Male |  |  |  |  |  | yes |  |  |  |  |
| calculate | meb_men_treated | Men treated |  |  | ${meb_5_14_male_treated} + ${meb_15_male_treated} |  |  |  |  |  |  |  |
| calculate | meb_women_treated | Women treated |  |  | ${meb_5_14_female_treated} + ${meb_15_male_treated} |  |  |  |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | meb_reason_not_treated | Reasons not treated with MEB |  | selected(${p_medicine}, 'PZQ+MEB') or selected(${p_medicine}, 'MEB')  |  |  |  |  |  |  |  |  |
| integer | meb_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | meb_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | ivm_by_sex | IVM By sex |  | selected(${p_medicine}, 'IVM') or selected(${p_medicine}, 'IVM+ALB+DEC') or selected(${p_medicine}, 'IVM+ALB') |  |  |  |  |  |  |  |  |
| integer | ivm_5_14_female_treated | 5-14 years old treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_5_14_male_treated | 5-14 years old treated Male |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_15_female_treated | 15 years and over treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_15_male_treated | 15 years and over treated Male |  |  |  |  |  | yes |  |  |  |  |
| calculate | ivm_men_treated | Men treated |  |  | ${ivm_5_14_male_treated} + ${ivm_15_male_treated} |  |  |  |  |  |  |  |
| calculate | ivm_women_treated | Women treated |  |  | ${ivm_5_14_female_treated} + ${ivm_15_male_treated} |  |  |  |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | ivm_reason_not_treated | Reasons not treated with IVM |  | selected(${p_medicine}, 'IVM') or selected(${p_medicine}, 'IVM+ALB+DEC') or selected(${p_medicine}, 'IVM+ALB') |  |  |  |  |  |  |  |  |
| integer | ivm_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | ivm_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | pzq_by_sex | PZQ By sex |  | selected(${p_medicine}, 'PZQ') or selected(${p_medicine}, 'PZQ+ALB')  |  |  |  |  |  |  |  |  |
| integer | pzq_5_14_female_treated | 5-14 years old treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_5_14_male_treated | 5-14 years old treated Male |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_15_female_treated | 15 years and over treated Female |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_15_male_treated | 15 years and over treated Male |  |  |  |  |  | yes |  |  |  |  |
| calculate | pzq_men_treated | Men treated |  |  | ${pzq_5_14_male_treated} + ${pzq_15_male_treated} |  |  |  |  |  |  |  |
| calculate | pzq_women_treated | Women treated |  |  | ${pzq_5_14_female_treated} + ${pzq_15_male_treated} |  |  |  |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | pzq_reason_not_treated | Reasons not treated with PZQ |  | selected(${p_medicine}, 'PZQ') or selected(${p_medicine}, 'PZQ+ALB')  |  |  |  |  |  |  |  |  |
| integer | pzq_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | pzq_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | azm_susp_by_sex | AZM Report Suspension by sex |  | selected(${p_medicine}, 'AZM.SUSP')  |  |  |  |  |  |  |  |  |
| integer | azm_susp_less7_boy_treated | Boys from 6 months to less than 7 years treated |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_susp_less7_girl_treated | Girls from 6 months to less than 7 years treated |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | azm_susp_reason_not_treated | Reasons not treated with AZM Suspension |  | selected(${p_medicine}, 'AZM.SUSP')  |  |  |  |  |  |  |  |  |
| integer | azm_susp_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_susp_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_susp_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | azm_tb_by_sex | AZM Report Tablet by sex |  | selected(${p_medicine}, 'AZM.TAB')  |  |  |  |  |  |  |  |  |
| integer | azm_tb_more7_boy_treated | Boys more than 7 years treated |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_tb_more7_girl_treated | Girls more than 7 years treated |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_tb_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | azm_tb_reason_not_treated | Reasons not treated with AZM Tablet |  | selected(${p_medicine}, 'AZM.TAB')  |  |  |  |  |  |  |  |  |
| integer | azm_tb_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_tb_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_tb_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | azm_tb_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | tetra_by_sex | TETRA By sex |  | selected(${p_medicine}, 'TETRA')  |  |  |  |  |  |  |  |  |
| integer | tetra_baby_boy | Baby boy less than six month |  |  |  |  |  | yes |  |  |  |  |
| integer | tetra_baby_girl | Baby girl less than six month |  |  |  |  |  | yes |  |  |  |  |
| integer | tetra_pregnant_women | Pregnant Women |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | tetra_reason_not_treated | reasons not treated with TETRA |  | selected(${p_medicine}, 'TETRA')  |  |  |  |  |  |  |  |  |
| integer | tetra_child | Children <90 cm untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | tetra_pregnant | Pregnant women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | tetra_breastfeeding | Breastfeeding women untreated  |  |  |  |  |  | yes |  |  |  |  |
| integer | tetra_absent | Absent |  |  |  |  |  | yes |  |  |  |  |
| integer | tetra_refusal | Refusal |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | cd_who_distributed | CD who distributed during this year |  |  |  |  |  |  |  |  |  |  |
| integer | cd_who_distributed_man | Community DistributorMen |  |  |  |  |  | yes |  |  |  |  |
| integer | cd_who_distributed_woman | Community Distributor Women |  |  |  |  |  | yes |  |  |  |  |
| integer | cd_trained | CD newly trained |  |  |  |  |  | yes |  |  |  |  |
| integer | cd_recycled | CD Recycled |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| text | p_add_note | Additional Note |  |  |  |  |  | no |  |  |  |  |
| start | p_start |  |  |  |  |  |  |  |  |  |  |  |
| end | p_end |  |  |  |  |  |  |  |  |  |  |  |

### choices

| list_name | name | label::English | disease_filter |
|---|---|---|---|
| recorder_id | 01 | 01 |  |
| recorder_id | 02 | 02 |  |
| recorder_id | 03 | 03 |  |
| recorder_id | 04 | 04 |  |
| recorder_id | 05 | 05 |  |
| recorder_id | 06 | 06 |  |
| recorder_id | 07 | 07 |  |
| recorder_id | 08 | 08 |  |
| recorder_id | 09 | 09 |  |
| recorder_id | 10 | 10 |  |
| recorder_id | 11 | 11 |  |
| recorder_id | 12 | 12 |  |
| recorder_id | 99 | 99 |  |
| yes_no | Yes | Yes |  |
| yes_no | No | No |  |
| campaign_day | Day 1 | Day 1 |  |
| campaign_day | Day 2 | Day 2 |  |
| campaign_day | Day 3 | Day 3 |  |
| campaign_day | Day 4 | Day 4 |  |
| campaign_day | Day 5 | Day 5 |  |
| campaign_day | Day 6 | Day 6 |  |
| campaign_day | Day 7 | Day 7 |  |
| campaign_day | Day 8 | Day 8 |  |
| campaign_day | Day 9 | Day 9 |  |
| campaign_day | Day 10 | Day 10 |  |
| disease | LF | LF |  |
| disease | ONCHO | ONCHO |  |
| disease | SCHISTO | SCHISTO |  |
| disease | STH | STH |  |
| disease | TRACHOMA | TRACHOMA |  |
| medicine | IVM | IVM | ONCHO |
| medicine | IVM+ALB | IVM+ALB | LF |
| medicine | IVM+ALB+DEC | IVM+ALB+DEC | LF |
| medicine | ALB | ALB | STH |
| medicine | TETRA | TETRA | TRACHOMA |
| medicine | AZM.TAB | AZM TAB | TRACHOMA |
| medicine | AZM.SUSP | AZM SUSP | TRACHOMA |
| medicine | MEB | MEB | STH |
| medicine | PZQ | PZQ | SCHISTO |
| medicine | PZQ+ALB | PZQ+ALB | SCHISTO |
| medicine | PZQ+MEB | PZQ+MEB | SCHISTO |
| census_method | Household-Level Digitization  | Household-Level Digitization  |  |
| census_method | Aggregate Reporting  | Aggregate Reporting  |  |

## demo_mda_9999_4_case_mngnt.xlsx

**settings:** `form_title`=(Demo) 4. MDA Medicine Use and Case Management Form V3; `form_id`=demo_mda_9999_4_case_mngnt_v3; `default_language`=English

### survey

| type | name | label | hint | relevant | calculation | constraint | constraint_message | required | appearance | choice_filter | default | read_only |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| string | p_state | Select State / Region / Province |  |  |  |  |  | yes |  |  |  |  |
| string | p_district | Select District / LGA / County |  |  |  |  |  | yes |  |  |  |  |
| string | p_health_facility | Enter the Health facility / Sub district |  |  |  |  |  | yes |  |  |  |  |
| select_multiple disease | p_disease | Disease covered by the TDM |  |  |  |  |  | yes |  |  |  |  |
| select_multiple medicine | p_medicine | Select the medcine package |  |  |  | not(   selected(${p_disease}, 'LF') and   selected(${p_disease}, 'ONCHO') and   selected(${p_medicine}, 'IVM') ) and not(   selected(${p_disease}, 'STH') and   selected(${p_disease}, 'SCHISTO') and   (     selected(${p_medicine}, 'ALB') or     selected(${p_medicine}, 'MEB') or     selected(${p_medicine}, 'PZQ')   ) ) and not(   selected(${p_disease}, 'SCHISTO') and   not(selected(${p_disease}, 'STH')) and   (     selected(${p_medicine}, 'PZQ+ALB') or     selected(${p_medicine}, 'PZQ+MEB')   ) ) and not(selected(${p_medicine}, 'IVM') and not(selected(${p_disease}, 'ONCHO') and not(selected(${p_disease}, 'LF')))) and not(selected(${p_medicine}, 'IVM+ALB') and not(selected(${p_disease}, 'LF') or selected(${p_disease}, 'ONCHO'))) and not(selected(${p_medicine}, 'IVM+ALB+DEC') and not(selected(${p_disease}, 'LF'))) and not(selected(${p_medicine}, 'ALB') and not(selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'MEB') and not(selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'PZQ') and not(selected(${p_disease}, 'SCHISTO'))) and not(selected(${p_medicine}, 'PZQ+ALB') and not(selected(${p_disease}, 'SCHISTO') or selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'PZQ+MEB') and not(selected(${p_disease}, 'SCHISTO') or selected(${p_disease}, 'STH'))) and not(selected(${p_medicine}, 'AZM.TAB') and not(selected(${p_disease}, 'TRACHOMA'))) and not(selected(${p_medicine}, 'AZM.SUSP') and not(selected(${p_disease}, 'TRACHOMA'))) and not(selected(${p_medicine}, 'TETRA') and not(selected(${p_disease}, 'TRACHOMA'))) | You cannot select a single medicine together with its combination version | yes |  |  selected(${p_disease}, disease_filter) |  |  |
| begin group | med_distr | Medicines Distributed |  |  |  |  |  |  |  |  |  |  |
| integer | p_total_pzq_dist | Total Praziquantel distributed |  | selected(${p_medicine}, 'PZQ') or selected(${p_medicine}, 'PZQ+ALB') or selected(${p_medicine}, 'PZQ+MEB') |  |  |  | yes |  |  |  |  |
| integer | p_total_alb_dist | Total Albendazole distributed |  | selected(${p_medicine}, 'ALB') or selected(${p_medicine}, 'IVM+ALB') or selected(${p_medicine}, 'IVM+ALB+DEC') or selected(${p_medicine}, 'PZQ+ALB') |  |  |  | yes |  |  |  |  |
| integer | p_total_meb_dist | Total Mebendazole distributed |  | selected(${p_medicine}, 'MEB') or selected(${p_medicine}, 'PZQ+MEB') |  |  |  | yes |  |  |  |  |
| integer | p_total_ivm_dist | Total Ivermectin distributed |  | selected(${p_medicine}, 'IVM') or selected(${p_medicine}, 'IVM+ALB') or selected(${p_medicine}, 'IVM+ALB+DEC') |  |  |  | yes |  |  |  |  |
| integer | p_total_dec_dist | Total Diethylcarbamazine distributed |  | selected(${p_medicine}, 'IVM+ALB+DEC') |  |  |  | yes |  |  |  |  |
| integer | p_total_az_sus_dist | Total Azithromycin suspension (in l) distributed |  | selected(${p_medicine}, 'AZM.SUSP') |  |  |  | yes |  |  |  |  |
| integer | p_total_az_tab_dist | Total Azithromycin tablets distributed |  | selected(${p_medicine}, 'AZM.TAB') |  |  |  | yes |  |  |  |  |
| integer | p_total_tetra_dist | Total Tetracycline distributed |  | selected(${p_medicine}, 'TETRA') |  |  |  | yes |  |  |  |  |
| integer | p_minor_side_effect | Number of cases of minor side effects |  |  |  |  |  | yes |  |  |  |  |
| integer | p_serious_side_effect | Number of cases of serious side effects |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin group | other_ntd_rep | Cases of other NTDs identified |  |  |  |  |  |  |  |  |  |  |
| integer | p_guinea_worm_rumor | Number of Guinea Worm rumors |  |  |  |  |  | yes |  |  |  |  |
| integer | p_leish_suspect | Number of suspected cases of Leishmaniasis |  |  |  |  |  | yes |  |  |  |  |
| integer | p_buruli_ulcer_suspect | Number of suspected cases of Buruli ulcer |  |  |  |  |  | yes |  |  |  |  |
| integer | p_Lymphoedema_LF | Number of cases with LF lymphoedema |  |  |  |  |  | yes |  |  |  |  |
| integer | P_hydrocele_LF | Number of cases with LF Hydrocele |  |  |  |  |  | yes |  |  |  |  |
| end group |  |  |  |  |  |  |  |  |  |  |  |  |
| text | p_add_note | Additional Note |  |  |  |  |  | no |  |  |  |  |
| start | p_start |  |  |  |  |  |  |  |  |  |  |  |
| end | p_end |  |  |  |  |  |  |  |  |  |  |  |

### choices

| list_name | name | label::English | disease_filter |
|---|---|---|---|
| recorder_id | 01 | 01 |  |
| recorder_id | 02 | 02 |  |
| recorder_id | 03 | 03 |  |
| recorder_id | 04 | 04 |  |
| recorder_id | 05 | 05 |  |
| recorder_id | 06 | 06 |  |
| recorder_id | 07 | 07 |  |
| recorder_id | 08 | 08 |  |
| recorder_id | 09 | 09 |  |
| recorder_id | 10 | 10 |  |
| recorder_id | 11 | 11 |  |
| recorder_id | 12 | 12 |  |
| recorder_id | 99 | 99 |  |
| yes_no | Yes | Yes |  |
| yes_no | No | No |  |
| disease | LF | LF |  |
| disease | ONCHO | ONCHO |  |
| disease | SCHISTO | SCHISTO |  |
| disease | STH | STH |  |
| disease | TRACHOMA | TRACHOMA |  |
| medicine | IVM | IVM | ONCHO |
| medicine | IVM+ALB | IVM+ALB | LF |
| medicine | IVM+ALB+DEC | IVM+ALB+DEC | LF |
| medicine | ALB | ALB | STH |
| medicine | TETRA | TETRA | TRACHOMA |
| medicine | AZM.TAB | AZM TAB | TRACHOMA |
| medicine | AZM.SUSP | AZM SUSP | TRACHOMA |
| medicine | MEB | MEB | STH |
| medicine | PZQ | PZQ | SCHISTO |
| medicine | PZQ+ALB | PZQ+ALB | SCHISTO |
| medicine | PZQ+MEB | PZQ+MEB | SCHISTO |

## demo_mda_9999_5_supervision_hf.xlsx

**settings:** `form_title`=(Demo) 5. MDA Supervision Health facility V3; `form_id`=demo_mda_9999_5_supervision_hf_v3; `default_language`=English

### survey

| type | name | label | hint | relevant | calculation | constraint | constraint_message | required | appearance | choice_filter | default | read_only |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| select_one recorder_id | s_recorder_id | Select the recorder ID |  |  |  |  |  |  |  |  |  |  |
| select_one state | s_state | Select region |  |  |  |  |  | yes |  |  |  |  |
| select_one district | s_district | Select district |  |  |  |  |  | yes |  | state = ${s_state} |  |  |
| select_one health_facility | s_health_facility | Health facility |  |  |  |  |  | yes |  | district = ${s_district} |  |  |
| select_one location | s_location | Village |  |  |  |  |  | yes |  | health_facility = ${s_health_facility} |  |  |
| select_one supervisor | s_supervisor_Level | Supervisor level |  |  |  |  |  | yes |  |  |  |  |
| date | s_date_start | Campaign start date |  |  |  |  |  | yes |  |  |  |  |
| date | s_date_end | Campaign end date |  |  |  |  |  | yes |  |  |  |  |
| select_multiple disease | s_disease | Disease covered by the MDA |  |  |  |  |  | yes |  |  |  |  |
| select_multiple medicine | s_medicine | Select the medicine package |  |  |  | not(   selected(${s_disease}, 'LF') and   selected(${s_disease}, 'ONCHO') and   selected(${s_medicine}, 'IVM') ) and not(   selected(${s_disease}, 'STH') and   selected(${s_disease}, 'SCHISTO') and   (     selected(${s_medicine}, 'ALB') or     selected(${s_medicine}, 'MEB') or     selected(${s_medicine}, 'PZQ')   ) ) and not(   selected(${s_disease}, 'SCHISTO') and   not(selected(${s_disease}, 'STH')) and   (     selected(${s_medicine}, 'PZQ+ALB') or     selected(${s_medicine}, 'PZQ+MEB')   ) ) and not(selected(${s_medicine}, 'IVM') and not(selected(${s_disease}, 'ONCHO') and not(selected(${s_disease}, 'LF')))) and not(selected(${s_medicine}, 'IVM+ALB') and not(selected(${s_disease}, 'LF') or selected(${s_disease}, 'ONCHO'))) and not(selected(${s_medicine}, 'IVM+ALB+DEC') and not(selected(${s_disease}, 'LF'))) and not(selected(${s_medicine}, 'ALB') and not(selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'MEB') and not(selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'PZQ') and not(selected(${s_disease}, 'SCHISTO'))) and not(selected(${s_medicine}, 'PZQ+ALB') and not(selected(${s_disease}, 'SCHISTO') or selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'PZQ+MEB') and not(selected(${s_disease}, 'SCHISTO') or selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'AZM.TAB') and not(selected(${s_disease}, 'TRACHOMA'))) and not(selected(${s_medicine}, 'AZM.SUSP') and not(selected(${s_disease}, 'TRACHOMA'))) and not(selected(${s_medicine}, 'TETRA') and not(selected(${s_disease}, 'TRACHOMA'))) | You cannot select a single medicine together with its combination version | yes |  |  selected(${s_disease}, disease_filter) |  |  |
| begin_group | location | Geographic coverage |  |  |  |  |  |  | field-list |  |  |  |
| integer | s_nb_villages_total | Total number of villages |  |  |  |  |  | yes |  |  |  |  |
| integer | s_nb_villages_treated | Number of villages treated |  |  |  |  |  | yes |  |  |  |  |
| integer | s_nb_villages_non_treated | Number of villages not treated |  |  |  |  |  | no |  |  |  |  |
| select_multiple reasons_non_treatment | s_reason_non_treatment | Reasons for non-treatment |  | ${s_nb_villages_non_treated} > 0 |  |  |  | no |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_ivm | Ivermectine Medication Management  |  | selected(${s_medicine}, 'IVM') or selected(${s_medicine}, 'IVM+ALB') or selected(${s_medicine}, 'IVM+ALB+DEC') |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_ivm | Is there any Ivermectine remaining stock? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_ivm | Are there any expired Ivermectine medications? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_ivm | Does the physical stock of Ivermectine match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_alb | Albendazole Medication Management |  | selected(${s_medicine}, 'ALB') or selected(${s_medicine}, 'IVM+ALB') or selected(${s_medicine}, 'IVM+ALB+DEC') or selected(${s_medicine}, 'PZQ+ALB')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_alb | Is there any Albendazole remaining stock? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_alb | Are there any expired Albendazole medications? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_alb | Does the physical stock of Albendazole match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_meb | Mebendazole Medication Management |  | selected(${s_medicine}, 'MEB') or selected(${s_medicine}, 'PZQ+MEB')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_meb | Is there any Mebendazole remaining stock? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_meb | Are there any expired Mebendazole medications? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_meb | Does the physical stock of Mebendazole match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_dec | Diethylcarbamazine Medication Management |  | selected(${s_medicine}, 'IVM+ALB+DEC')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_dec | Is there any Diethylcarbamazine remaining stock? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_dec | Are there any expired Diethylcarbamazine medications? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_dec | Does the physical stock of Diethylcarbamazine match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_pzq | Praziquantel Medication Management |  | selected(${s_medicine}, 'PZQ+ALB') or selected(${s_medicine}, 'PZQ+MEB') or selected(${s_medicine}, 'PZQ')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_pzq | Is there any Praziquantel remaining stock? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_pzq | Are there any Praziquantel expired medications? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_pzq | Does the physical stock of Praziquantel match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_az_sus | Azytromicine Suspension Medication Management |  | selected(${s_medicine}, 'AZM.SUSP')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_az_sus | Is there any remaining stock of Azytromicine Suspension? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_az_sus | Are there any expired Azytromicine suspension? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_az_sus | Does the physical stock of Azytromicine suspension match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_az_tab | Azytromicine tablet Medication Management |  | selected(${s_medicine}, 'AZM.TAB')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_az_tab | Is there any remaining stock of Azytromicine tablet? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_az_tab | Are there any expired medications of Azytromicine tablet? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_az_tab | Does the physical stock of Azytromicine tablet match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | logistic_tetra | Medication Management |  | selected(${s_medicine}, 'TETRA')  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_stock_remain_tetra | Is there any remaining stock? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_expired_tetra | Are there any expired medications? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_stock_concordance_tetra | Does the physical stock match the theoretical stock? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | s_training | Distributor training |  |  |  |  |  |  | field-list |  |  |  |
| integer | s_dc_trained_h | Number of male distributors trained |  |  |  |  |  | yes |  |  |  |  |
| integer | s_dc_trained_f | Number of female distributors trained |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_manual_used | Distributor manual used? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | s_mobilisation | Social Mobilisation |  |  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_population_informed | Was the population informed before the campaign? |  |  |  |  |  | yes |  |  |  |  |
| select_multiple channel_com | s_chanel_utilises | Communication channels used |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | s_supervision | Area of supervision |  |  |  |  |  |  | field-list |  |  |  |
| integer | s_dc_supervised | Number of distributors supervised |  |  |  |  |  | yes |  |  |  |  |
| integer | s_villages_supervised | Number of villages supervised |  |  |  |  |  | no |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | s_pharmacovigilance | Pharmacovigilance |  |  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_side_effect | Were any adverse effects reported? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_sever_side_effect | Were any serious adverse effects reported? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| text | s_difficultes | Challenges encountered |  |  |  |  |  | no |  |  |  |  |
| text | s_solutions | Proposed solutions |  |  |  |  |  | no |  |  |  |  |
| text | s_recommandations | Supervisor recommendations |  |  |  |  |  | no |  |  |  |  |
| start | start |  |  |  |  |  |  |  |  |  |  |  |
| end | end |  |  |  |  |  |  |  |  |  |  |  |

### choices

| list_name | name | label::English | disease_filter | state | district | health_facility | location |
|---|---|---|---|---|---|---|---|
| recorder_id | 01 | 01 |  |  |  |  |  |
| recorder_id | 02 | 02 |  |  |  |  |  |
| recorder_id | 03 | 03 |  |  |  |  |  |
| recorder_id | 04 | 04 |  |  |  |  |  |
| recorder_id | 05 | 05 |  |  |  |  |  |
| recorder_id | 06 | 06 |  |  |  |  |  |
| recorder_id | 07 | 07 |  |  |  |  |  |
| recorder_id | 08 | 08 |  |  |  |  |  |
| recorder_id | 09 | 09 |  |  |  |  |  |
| recorder_id | 10 | 10 |  |  |  |  |  |
| recorder_id | 11 | 11 |  |  |  |  |  |
| recorder_id | 12 | 12 |  |  |  |  |  |
| recorder_id | 99 | 99 |  |  |  |  |  |
| yes_no | Yes | Yes |  |  |  |  |  |
| yes_no | No | No |  |  |  |  |  |
| reasons_non_treatment | Absence.of.DC | Absence of DC |  |  |  |  |  |
| reasons_non_treatment | Population.refusal | Population refusal |  |  |  |  |  |
| reasons_non_treatment | Medication.shortage | Medication shortage |  |  |  |  |  |
| reasons_non_treatment | Insecurity | Insecurity |  |  |  |  |  |
| reasons_non_treatment | Difficult.access | Difficult access |  |  |  |  |  |
| reasons_non_treatment | Not.Required | Not Required |  |  |  |  |  |
| supervisor | National | National |  |  |  |  |  |
| supervisor | Regional | Regional |  |  |  |  |  |
| supervisor | District | District |  |  |  |  |  |
| supervisor | Partner | Partner |  |  |  |  |  |
| supervisor | Health_facility | Health facility |  |  |  |  |  |
| channel_com | Radio | Radio |  |  |  |  |  |
| channel_com | Town.criers | Town criers |  |  |  |  |  |
| channel_com | Community.leaders | Community leaders |  |  |  |  |  |
| channel_com | Schools | Schools |  |  |  |  |  |
| channel_com | Posters | Posters |  |  |  |  |  |
| disease | LF | LF |  |  |  |  |  |
| disease | ONCHO | ONCHO |  |  |  |  |  |
| disease | SCHISTO | SCHISTO |  |  |  |  |  |
| disease | STH | STH |  |  |  |  |  |
| disease | TRACHOMA | TRACHOMA |  |  |  |  |  |
| medicine | IVM | IVM | ONCHO |  |  |  |  |
| medicine | IVM+ALB | IVM+ALB | LF |  |  |  |  |
| medicine | IVM+ALB+DEC | IVM+ALB+DEC | LF |  |  |  |  |
| medicine | ALB | ALB | STH |  |  |  |  |
| medicine | TETRA | TETRA | TRACHOMA |  |  |  |  |
| medicine | AZM.TAB | AZM TAB | TRACHOMA |  |  |  |  |
| medicine | AZM.SUSP | AZM SUSP | TRACHOMA |  |  |  |  |
| medicine | MEB | MEB | STH |  |  |  |  |
| medicine | PZQ | PZQ | SCHISTO |  |  |  |  |
| medicine | PZQ+ALB | PZQ+ALB | SCHISTO |  |  |  |  |
| medicine | PZQ+MEB | PZQ+MEB | SCHISTO |  |  |  |  |
| state | Bandundu | Bandundu |  |  |  |  |  |
| state | Bas-Congo | Bas-Congo |  |  |  |  |  |
| state | Haut-Katanga | Haut-Katanga |  |  |  |  |  |
| state | Ituri | Ituri |  |  |  |  |  |
| state | Kasai-Central | Kasai-Central |  |  |  |  |  |
| state | Kasai-Oriental | Kasai-Oriental |  |  |  |  |  |
| state | Kwango | Kwango |  |  |  |  |  |
| state | Lualaba | Lualaba |  |  |  |  |  |
| state | Nord-Kivu | Nord-Kivu |  |  |  |  |  |
| state | Sud-Kivu | Sud-Kivu |  |  |  |  |  |
| district | Bagata | Bagata |  | Bandundu |  |  |  |
| district | Bulungu | Bulungu |  | Bandundu |  |  |  |
| district | Boma | Boma |  | Bas-Congo |  |  |  |
| district | Matadi | Matadi |  | Bas-Congo |  |  |  |
| district | Kambove | Kambove |  | Haut-Katanga |  |  |  |
| district | Kipushi | Kipushi |  | Haut-Katanga |  |  |  |
| district | Bunia | Bunia |  | Ituri |  |  |  |
| district | Mambasa | Mambasa |  | Ituri |  |  |  |
| district | Dibaya | Dibaya |  | Kasai-Central |  |  |  |
| district | Kazumba | Kazumba |  | Kasai-Central |  |  |  |
| district | Lupatapata | Lupatapata |  | Kasai-Oriental |  |  |  |
| district | Miabi | Miabi |  | Kasai-Oriental |  |  |  |
| district | Kenge | Kenge |  | Kwango |  |  |  |
| district | Popokabaka | Popokabaka |  | Kwango |  |  |  |
| district | Fungurume | Fungurume |  | Lualaba |  |  |  |
| district | Kolwezi | Kolwezi |  | Lualaba |  |  |  |
| district | Beni | Beni |  | Nord-Kivu |  |  |  |
| district | Rutshuru | Rutshuru |  | Nord-Kivu |  |  |  |
| district | Kalehe | Kalehe |  | Sud-Kivu |  |  |  |
| district | Uvira | Uvira |  | Sud-Kivu |  |  |  |
| health_facility | Kikongo Centre | Kikongo Centre |  |  | Bagata |  |  |
| health_facility | Oicha Centre | Oicha Centre |  |  | Beni |  |  |
| health_facility | Nzadi Centre | Nzadi Centre |  |  | Boma |  |  |
| health_facility | Niadi Centre | Niadi Centre |  |  | Bulungu |  |  |
| health_facility | Mudzipela Centre | Mudzipela Centre |  |  | Bunia |  |  |
| health_facility | Tshikapa Centre | Tshikapa Centre |  |  | Dibaya |  |  |
| health_facility | Tenke Centre | Tenke Centre |  |  | Fungurume |  |  |
| health_facility | Ihusi Centre | Ihusi Centre |  |  | Kalehe |  |  |
| health_facility | Kakanda Centre | Kakanda Centre |  |  | Kambove |  |  |
| health_facility | Musese | Musese |  |  | Kazumba |  |  |
| health_facility | Bukanga | Bukanga |  |  | Kenge |  |  |
| health_facility | Lumata Centre | Lumata Centre |  |  | Kipushi |  |  |
| health_facility | Dilala Centre | Dilala Centre |  |  | Kolwezi |  |  |
| health_facility | Mulenda | Mulenda |  |  | Lupatapata |  |  |
| health_facility | Makeke Centre | Makeke Centre |  |  | Mambasa |  |  |
| health_facility | Kinkanda Centre | Kinkanda Centre |  |  | Matadi |  |  |
| health_facility | Katende Centre | Katende Centre |  |  | Miabi |  |  |
| health_facility | Yasa Bonga | Yasa Bonga |  |  | Popokabaka |  |  |
| health_facility | Kiwanja Centre | Kiwanja Centre |  |  | Rutshuru |  |  |
| health_facility | Kavimvira Centre | Kavimvira Centre |  |  | Uvira |  |  |
| location | Misangi | Misangi |  |  |  | Bukanga |  |
| location | Mutoshi | Mutoshi |  |  |  | Dilala Centre |  |
| location | Nyabibwe | Nyabibwe |  |  |  | Ihusi Centre |  |
| location | Mwadingusha | Mwadingusha |  |  |  | Kakanda Centre |  |
| location | Kalelu | Kalelu |  |  |  | Katende Centre |  |
| location | Sange | Sange |  |  |  | Kavimvira Centre |  |
| location | Kimputu | Kimputu |  |  |  | Kikongo Centre |  |
| location | Soyo | Soyo |  |  |  | Kinkanda Centre |  |
| location | Bwito | Bwito |  |  |  | Kiwanja Centre |  |
| location | Kafubu | Kafubu |  |  |  | Lumata Centre |  |
| location | Biakato | Biakato |  |  |  | Makeke Centre |  |
| location | Hoho | Hoho |  |  |  | Mudzipela Centre |  |
| location | Mbujimayi Rural | Mbujimayi Rural |  |  |  | Mulenda |  |
| location | Lubudi | Lubudi |  |  |  | Musese |  |
| location | Kiyaka | Kiyaka |  |  |  | Niadi Centre |  |
| location | Lovo | Lovo |  |  |  | Nzadi Centre |  |
| location | Mavivi | Mavivi |  |  |  | Oicha Centre |  |
| location | Kando | Kando |  |  |  | Tenke Centre |  |
| location | Kabondo | Kabondo |  |  |  | Tshikapa Centre |  |
| location | Kipata | Kipata |  |  |  | Yasa Bonga |  |

## demo_mda_9999_6_supervision_CDD.xlsx

**settings:** `form_title`=(Demo) 6. MDA Supervision - CDD Form V3; `form_id`=demo_mda_9999_6_supervision_CDD_v3; `default_language`=English

### survey

| type | name | label | hint | relevant | calculation | constraint | constraint_message | required | appearance | choice_filter | default | read_only |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| select_one supervisor | s_supervisor | Supervisor Team |  |  |  |  |  |  |  |  |  |  |
| select_one state | s_state | Select region |  |  |  |  |  | yes |  |  |  |  |
| select_one district | s_district | Select district |  |  |  |  |  | yes |  | state = ${s_state} |  |  |
| select_one health_facility | s_health_facility | Health facility |  |  |  |  |  | yes |  | district = ${s_district} |  |  |
| select_one location | s_location | Village |  |  |  |  |  | yes |  | health_facility = ${s_health_facility} |  |  |
| date | s_date_start | Campaign start date |  |  |  |  |  | yes |  |  |  |  |
| date | s_date_end | Campaign end date |  |  |  |  |  | yes |  |  |  |  |
| select_multiple disease | s_disease | Disease covered by the MDA |  |  |  |  |  | yes |  |  |  |  |
| select_multiple medicine | s_medicine | Select the medicine package |  |  |  | not(   selected(${s_disease}, 'LF') and   selected(${s_disease}, 'ONCHO') and   selected(${s_medicine}, 'IVM') ) and not(   selected(${s_disease}, 'STH') and   selected(${s_disease}, 'SCHISTO') and   (     selected(${s_medicine}, 'ALB') or     selected(${s_medicine}, 'MEB') or     selected(${s_medicine}, 'PZQ')   ) ) and not(   selected(${s_disease}, 'SCHISTO') and   not(selected(${s_disease}, 'STH')) and   (     selected(${s_medicine}, 'PZQ+ALB') or     selected(${s_medicine}, 'PZQ+MEB')   ) ) and not(selected(${s_medicine}, 'IVM') and not(selected(${s_disease}, 'ONCHO') and not(selected(${s_disease}, 'LF')))) and not(selected(${s_medicine}, 'IVM+ALB') and not(selected(${s_disease}, 'LF') or selected(${s_disease}, 'ONCHO'))) and not(selected(${s_medicine}, 'IVM+ALB+DEC') and not(selected(${s_disease}, 'LF'))) and not(selected(${s_medicine}, 'ALB') and not(selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'MEB') and not(selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'PZQ') and not(selected(${s_disease}, 'SCHISTO'))) and not(selected(${s_medicine}, 'PZQ+ALB') and not(selected(${s_disease}, 'SCHISTO') or selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'PZQ+MEB') and not(selected(${s_disease}, 'SCHISTO') or selected(${s_disease}, 'STH'))) and not(selected(${s_medicine}, 'AZM.TAB') and not(selected(${s_disease}, 'TRACHOMA'))) and not(selected(${s_medicine}, 'AZM.SUSP') and not(selected(${s_disease}, 'TRACHOMA'))) and not(selected(${s_medicine}, 'TETRA') and not(selected(${s_disease}, 'TRACHOMA'))) | You cannot select a single medicine together with its combination version | yes |  |  selected(${s_disease}, disease_filter) |  |  |
| select_one yes_no | s_medicine_sufficient | Do the distributors have the medications in sufficient quantities? |  |  |  |  |  | yes |  |  |  |  |
| integer | s_total_dist_trained_male | Total Distributor Male Trained for the campagne |  |  |  |  |  | yes |  |  |  |  |
| integer | s_total_dist_trained_female | Total Distributor Female Trained for the campagne |  |  |  |  |  |  |  |  |  |  |
| calculate | s_total_dist | Total Distributor Trained |  |  | ${s_total_dist_trained_male} + ${s_total_dist_trained_female} |  |  |  |  |  |  |  |
| begin_group | MDA_supplies | Avaialability of MDA supplies |  |  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_hieght_chart | Height chart |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_register | Register |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_records_checklist | Records/checklist |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_med_bag | The CDD uses a medication bag |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| begin_group | attitude_CDD | Observe the actions, attitudes, and skills of the community health worker during the treatment of a family | wearing a vest, wearing a mask, using hand sanitizer, standard greetings - introduction -, administering medication, data collection |  |  |  |  |  | field-list |  |  |  |
| select_one yes_no | s_wear_vest | Is the community health worker/healthcare worker team identifiable by a vest? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_usual_greetings | The CDD proceeds with the usual greetings |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_introduced_patient | The CDD  introduces the patient by specifying the reason for their visit and the treatment being administered. |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_used_height_chart_correctly | The CDD  uses the height chart correctly. |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_gave_write_dosage | The CDD  administers the medication correctly according to the height chart reading. |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_medicine_took_in_front_of_dc | The medicine is taken in the presence of the DC  |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_filled_form | Does the CDD complete the data collection forms (checklist and register) correctly? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_investigated_cases | Does the CDD investigate and report cases of FL, Buruli ulcer, leishmaniasis and rumours of VG? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_identified_ineligible | Are ineligible individuals identified? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_follow_side_effect_procedure | Is the procedure to follow in the event of side events known? |  |  |  |  |  | yes |  |  |  |  |
| end_group |  |  |  |  |  |  |  |  |  |  |  |  |
| date | s_date_training | Date of training session |  |  |  |  |  | yes |  |  |  |  |
| integer | s_traning_duration | Duration of training session (in days) | In days |  |  |  |  | yes |  |  |  |  |
| select_multiple training | s_training_topic | What topics were covered during the training? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_took_med_in_training | Did you take the medication during the training? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_complete_form | Does the CDD complete the data collection forms (checklist and register) correctly? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_case_mngt | Does the CDD investigate and report cases of FL, Buruli ulcer, leishmaniasis and rumours of VG? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_has_inegidible | Are ineligible individuals identified? |  |  |  |  |  | yes |  |  |  |  |
| select_one yes_no | s_follow_side_effect | Is the procedure to follow in the event of adverse events known? |  |  |  |  |  | yes |  |  |  |  |
| text | s_difficultes | Challenges encountered |  |  |  |  |  | no |  |  |  |  |
| text | s_solutions | Proposed solutions |  |  |  |  |  | no |  |  |  |  |
| text | s_recommandations | Supervisor recommendations |  |  |  |  |  | no |  |  |  |  |
| start | start |  |  |  |  |  |  |  |  |  |  |  |
| end | end |  |  |  |  |  |  |  |  |  |  |  |

### choices

| list_name | name | label::English | disease_filter | state | district | health_facility | location |
|---|---|---|---|---|---|---|---|
| supervisor | National | National |  |  |  |  |  |
| supervisor | Regional | Regional |  |  |  |  |  |
| supervisor | Partner | Partner |  |  |  |  |  |
| supervisor | District | District |  |  |  |  |  |
| supervisor | Health_Facility | Health Facility |  |  |  |  |  |
| yes_no | Yes | Yes |  |  |  |  |  |
| yes_no | No | No |  |  |  |  |  |
| mda_type | Onchocerciasis | Onchocerciasis |  |  |  |  |  |
| mda_type | Lymphatic filariasis | Lymphatic filariasis |  |  |  |  |  |
| mda_type | Schistosomiasis | Schistosomiasis |  |  |  |  |  |
| mda_type | Geohelminthiasis | Geohelminthiasis |  |  |  |  |  |
| reasons_non_treatment | Absence.of.DC | Absence of DC |  |  |  |  |  |
| reasons_non_treatment | Population.refusal | Population refusal |  |  |  |  |  |
| reasons_non_treatment | Medication.shortage | Medication shortage |  |  |  |  |  |
| reasons_non_treatment | Insecurity | Insecurity |  |  |  |  |  |
| reasons_non_treatment | Difficult.access | Difficult access |  |  |  |  |  |
| channel_com | Radio | Radio |  |  |  |  |  |
| channel_com | Town.criers | Town criers |  |  |  |  |  |
| channel_com | Community.leaders | Community leaders |  |  |  |  |  |
| channel_com | Schools | Schools |  |  |  |  |  |
| channel_com | Posters | Posters |  |  |  |  |  |
| disease | LF | LF |  |  |  |  |  |
| disease | ONCHO | ONCHO |  |  |  |  |  |
| disease | SCHISTO | SCHISTO |  |  |  |  |  |
| disease | STH | STH |  |  |  |  |  |
| disease | TRACHOMA | TRACHOMA |  |  |  |  |  |
| training | Using.the.measuring.stick | Using the measuring stick |  |  |  |  |  |
| training | Completing.the.checklists | Completing the checklists |  |  |  |  |  |
| training | Supervised.taking | Supervised taking |  |  |  |  |  |
| training | Marking.concessions | Marking concessions |  |  |  |  |  |
| training | Monitoring.refusals | Monitoring refusals |  |  |  |  |  |
| training | Revisit | Revisit |  |  |  |  |  |
| training | Practical.exercise | Practical exercise |  |  |  |  |  |
| training | Interpersonal.communication | Interpersonal communication |  |  |  |  |  |
| training | Other | Other |  |  |  |  |  |
| medicine | IVM | IVM | ONCHO |  |  |  |  |
| medicine | IVM+ALB | IVM+ALB | LF |  |  |  |  |
| medicine | IVM+ALB+DEC | IVM+ALB+DEC | LF |  |  |  |  |
| medicine | ALB | ALB | STH |  |  |  |  |
| medicine | TETRA | TETRA | TRACHOMA |  |  |  |  |
| medicine | AZM.TAB | AZM TAB | TRACHOMA |  |  |  |  |
| medicine | AZM.SUSP | AZM SUSP | TRACHOMA |  |  |  |  |
| medicine | MEB | MEB | STH |  |  |  |  |
| medicine | PZQ | PZQ | SCHISTO |  |  |  |  |
| medicine | PZQ+ALB | PZQ+ALB | SCHISTO |  |  |  |  |
| medicine | PZQ+MEB | PZQ+MEB | SCHISTO |  |  |  |  |
| state | Bandundu | Bandundu |  |  |  |  |  |
| state | Bas-Congo | Bas-Congo |  |  |  |  |  |
| state | Haut-Katanga | Haut-Katanga |  |  |  |  |  |
| state | Ituri | Ituri |  |  |  |  |  |
| state | Kasai-Central | Kasai-Central |  |  |  |  |  |
| state | Kasai-Oriental | Kasai-Oriental |  |  |  |  |  |
| state | Kwango | Kwango |  |  |  |  |  |
| state | Lualaba | Lualaba |  |  |  |  |  |
| state | Nord-Kivu | Nord-Kivu |  |  |  |  |  |
| state | Sud-Kivu | Sud-Kivu |  |  |  |  |  |
| district | Bagata | Bagata |  | Bandundu |  |  |  |
| district | Bulungu | Bulungu |  | Bandundu |  |  |  |
| district | Boma | Boma |  | Bas-Congo |  |  |  |
| district | Matadi | Matadi |  | Bas-Congo |  |  |  |
| district | Kambove | Kambove |  | Haut-Katanga |  |  |  |
| district | Kipushi | Kipushi |  | Haut-Katanga |  |  |  |
| district | Bunia | Bunia |  | Ituri |  |  |  |
| district | Mambasa | Mambasa |  | Ituri |  |  |  |
| district | Dibaya | Dibaya |  | Kasai-Central |  |  |  |
| district | Kazumba | Kazumba |  | Kasai-Central |  |  |  |
| district | Lupatapata | Lupatapata |  | Kasai-Oriental |  |  |  |
| district | Miabi | Miabi |  | Kasai-Oriental |  |  |  |
| district | Kenge | Kenge |  | Kwango |  |  |  |
| district | Popokabaka | Popokabaka |  | Kwango |  |  |  |
| district | Fungurume | Fungurume |  | Lualaba |  |  |  |
| district | Kolwezi | Kolwezi |  | Lualaba |  |  |  |
| district | Beni | Beni |  | Nord-Kivu |  |  |  |
| district | Rutshuru | Rutshuru |  | Nord-Kivu |  |  |  |
| district | Kalehe | Kalehe |  | Sud-Kivu |  |  |  |
| district | Uvira | Uvira |  | Sud-Kivu |  |  |  |
| health_facility | Kikongo Centre | Kikongo Centre |  |  | Bagata |  |  |
| health_facility | Oicha Centre | Oicha Centre |  |  | Beni |  |  |
| health_facility | Nzadi Centre | Nzadi Centre |  |  | Boma |  |  |
| health_facility | Niadi Centre | Niadi Centre |  |  | Bulungu |  |  |
| health_facility | Mudzipela Centre | Mudzipela Centre |  |  | Bunia |  |  |
| health_facility | Tshikapa Centre | Tshikapa Centre |  |  | Dibaya |  |  |
| health_facility | Tenke Centre | Tenke Centre |  |  | Fungurume |  |  |
| health_facility | Ihusi Centre | Ihusi Centre |  |  | Kalehe |  |  |
| health_facility | Kakanda Centre | Kakanda Centre |  |  | Kambove |  |  |
| health_facility | Musese | Musese |  |  | Kazumba |  |  |
| health_facility | Bukanga | Bukanga |  |  | Kenge |  |  |
| health_facility | Lumata Centre | Lumata Centre |  |  | Kipushi |  |  |
| health_facility | Dilala Centre | Dilala Centre |  |  | Kolwezi |  |  |
| health_facility | Mulenda | Mulenda |  |  | Lupatapata |  |  |
| health_facility | Makeke Centre | Makeke Centre |  |  | Mambasa |  |  |
| health_facility | Kinkanda Centre | Kinkanda Centre |  |  | Matadi |  |  |
| health_facility | Katende Centre | Katende Centre |  |  | Miabi |  |  |
| health_facility | Yasa Bonga | Yasa Bonga |  |  | Popokabaka |  |  |
| health_facility | Kiwanja Centre | Kiwanja Centre |  |  | Rutshuru |  |  |
| health_facility | Kavimvira Centre | Kavimvira Centre |  |  | Uvira |  |  |
| location | Misangi | Misangi |  |  |  | Bukanga |  |
| location | Mutoshi | Mutoshi |  |  |  | Dilala Centre |  |
| location | Nyabibwe | Nyabibwe |  |  |  | Ihusi Centre |  |
| location | Mwadingusha | Mwadingusha |  |  |  | Kakanda Centre |  |
| location | Kalelu | Kalelu |  |  |  | Katende Centre |  |
| location | Sange | Sange |  |  |  | Kavimvira Centre |  |
| location | Kimputu | Kimputu |  |  |  | Kikongo Centre |  |
| location | Soyo | Soyo |  |  |  | Kinkanda Centre |  |
| location | Bwito | Bwito |  |  |  | Kiwanja Centre |  |
| location | Kafubu | Kafubu |  |  |  | Lumata Centre |  |
| location | Biakato | Biakato |  |  |  | Makeke Centre |  |
| location | Hoho | Hoho |  |  |  | Mudzipela Centre |  |
| location | Mbujimayi Rural | Mbujimayi Rural |  |  |  | Mulenda |  |
| location | Lubudi | Lubudi |  |  |  | Musese |  |
| location | Kiyaka | Kiyaka |  |  |  | Niadi Centre |  |
| location | Lovo | Lovo |  |  |  | Nzadi Centre |  |
| location | Mavivi | Mavivi |  |  |  | Oicha Centre |  |
| location | Kando | Kando |  |  |  | Tenke Centre |  |
| location | Kabondo | Kabondo |  |  |  | Tshikapa Centre |  |
| location | Kipata | Kipata |  |  |  | Yasa Bonga |  |