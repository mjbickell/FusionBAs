select req.REQUISITION_ID
  , sub.person_id
  , req.REQUISITION_NUMBER
  , title.REQUISITION_NAME
  , req_phase.PHASE_NAME|| ' - ' ||req_state.STATE_NAME as REQ_CURRENT_STATUS
  , req.open_date
  , case
     when sub.SUBMISSION_ID is not null
     then sub_phase.PHASE_NAME|| ' - ' ||sub_state.STATE_NAME 
     else null
    end SUB_CURRENT_STATUS
  , reas.SUB_STATUS_REASON
  , sub.ACTIVE
  , sname.SOURCE_MEDIUM
  , cxsite.CAREER_SITE
  , dept.department_name
  , cand.candidate_number
  , pname.CANDIDATE_NAME
  , attr.gender
  , case when attr.ETHNICITY_CODE = 4 then attr.ethnicity
    else null
    end ethnicity
  , case when attr.ETHNICITY_CODE != 4 then attr.ethnicity
    else null
    end race
  , attr.veterans_preference
  , attr.disability
  , vets.Disabled_Veteran
  , vets.ACTIVE_DUTY_WARTIME
  , vets.ARMED_FORCES_MEDAL
  , vets.RECENTLY_SEPARATED_VETERAN
  , ethn.ethnicity as new_ethnicity
  , ethn.race as new_race

from
/* REQUISITIONS */
(select REQUISITION_ID
  , REQUISITION_NUMBER
  , CURRENT_PHASE_ID
  , CURRENT_STATE_ID
  , hiring_manager_id
  , job_id
  , department_id
  , OBJECT_STATUS
  , open_date
from IRC_REQUISITIONS_B
where REQ_USAGE_CODE = 'ORA_REQUISITION') REQ

/* TITLE */
, (select REQUISITION_ID
  , TITLE as REQUISITION_NAME
from IRC_REQUISITIONS_TL) TITLE

/*REQUISITION CURRENT STATUS */
, (select distinct phase_id
  , name as PHASE_NAME 
from IRC_PHASES_TL) REQ_PHASE

, (select distinct state_id
  , name as STATE_NAME 
from IRC_STATES_TL) REQ_STATE

/* DEPARTMENT */
, (select organization_id
  , name as DEPARTMENT_NAME
from hr_organization_units_f_tl
where trunc(sysdate) between effective_start_date and effective_end_date) DEPT

/* SUBMISSIONS */
, (select REQUISITION_ID
  , PERSON_ID
  , SUBMISSION_ID
  , CURRENT_PHASE_ID
  , CURRENT_STATE_ID
  , PROCESS_ID
  , decode(ACTIVE_FLAG,'Y','Yes'
                       ,'N','No'
                       , ACTIVE_FLAG) as ACTIVE 
from IRC_SUBMISSIONS
) SUB

/* SUBMISSION CURRENT STATUS */
, (select distinct phase_id
  , name as PHASE_NAME 
from IRC_PHASES_TL) SUB_PHASE

, (select distinct state_id
  , name as STATE_NAME 
from IRC_STATES_TL) SUB_STATE

/* REASONS BASED ON STATE AND HISTORY */
, (select SUBJECT_ID as SUBMISSION_ID
  , STATE_ID
  , REASON_ID
from IRC_LC_HISTORY
where subject_id is not null
and state_id is not null
and reason_id is not null) HIST

, (select REASON_ID
  , REASON_NAME as SUB_STATUS_REASON
from IRC_LC_REASONS_TL) REAS

/* SOURCE TRACKING */
, (select REQUISITION_ID
  , SUBMISSION_ID
  , DIMENSION_ID
  , CANDIDATE_NUMBER
  , SITE_NUMBER
from IRC_SOURCE_TRACKING
where REQUISITION_ID is not null
and SUBMISSION_ID is not null) STRACK

/* SOURCE DETAILS */
, (select dimb.DIMENSION_ID
  , case 
    when med.MEANING is not null and dimtl.SOURCE_NAME is not null
    then med.MEANING||' - '||dimtl.SOURCE_NAME
    when med.MEANING is not null
    then med.MEANING
    else dimtl.SOURCE_NAME
    end as SOURCE_MEDIUM
from IRC_DIMENSION_DEF_B dimb
join IRC_DIMENSION_DEF_TL dimtl on dimb.dimension_id = dimtl.dimension_id
left join FND_LOOKUP_VALUES_VL med on dimb.SOURCE_MEDIUM = med.lookup_code
                          and med.lookup_type = 'ORA_IRC_SOURCE_TRACKING_MEDIUM') SNAME

/* SOURCE SITE DETAILS */ 
, (select cxb.SITE_NUMBER
  , cxtl.SITE_NAME as CAREER_SITE
from IRC_CX_SITES_B cxb 
join IRC_CX_SITES_TL cxtl on cxb.site_id = cxtl.site_id) CXSITE

/* CANDIDATE NUMBER */
, (select person_id
  , candidate_number
from IRC_CANDIDATES
order by candidate_number) CAND

/* CANDIDATE NAME */
, (select person_id
  , full_name as CANDIDATE_NAME
from per_person_names_f
where name_type = 'GLOBAL'
and trunc(sysdate) between effective_start_date and effective_end_date) PNAME

/* ATTRIBUTES */
, (select person_id
  , submission_id
  , ATTRIBUTE_1 as GENDER_CODE
  , SEX.meaning as GENDER
  , ATTRIBUTE_2 as ETHNICITY_CODE
  , ETHN.meaning as ETHNICITY
  , ATTRIBUTE_3 as VETERANS_PREFERENCE_CODE
  , VETS.meaning as VETERANS_PREFERENCE
  , ATTRIBUTE_4 as DISABILITY_CODE
  , DIS.meaning as DISABILITY
from IRC_REGULATORY_RESPONSES REG 
left join hr_lookups sex on REG.ATTRIBUTE_1 = sex.lookup_code
                        and sex.lookup_type = 'SEX'
left join FND_LOOKUP_VALUES_VL ethn on REG.ATTRIBUTE_2 = ethn.lookup_code
                        and ethn.lookup_type = 'ORA_PER_ETHNICITY'
left join hr_lookups vets on REG.ATTRIBUTE_3 = vets.lookup_code
                        and vets.lookup_type = 'ORA_HRX_US_VETS_SELFID_STATUS'
left join FND_LOOKUP_VALUES_VL dis on REG.ATTRIBUTE_4 = dis.lookup_code
                          and dis.lookup_type = 'ORA_PER_SELF_DISCLOSE_DISABILI') ATTR

, (select person_id
, decode(PER_INFORMATION11,'Y','Yes'
							    ,'N','No'
								,PER_INFORMATION11) as Disabled_Veteran
, decode(PER_INFORMATION12,'Y','Yes'
							    ,'N','No'
								,PER_INFORMATION12) as ACTIVE_DUTY_WARTIME
, decode(PER_INFORMATION13,'Y','Yes'
							    ,'N','No'
								,PER_INFORMATION13) as ARMED_FORCES_MEDAL
, decode(PER_INFORMATION15,'Y','Yes'
							    ,'N','No'
								,PER_INFORMATION15) as RECENTLY_SEPARATED_VETERAN		
   FROM PER_PEOPLE_LEGISLATIVE_F 
   where trunc(sysdate) between nvl(effective_start_date,sysdate) and nvl(effective_end_date,sysdate)) VETS

, (select eth.submission_id 
  , eth.person_id
  , eth.ETHNICITY
  , case when eth.ETHNICITY is null then
		case 
			when UPPER(eth.ETHNICITY_STATUS) like '%YES%YES%' then 'Two or more races'
			when UPPER(eth.ETHNICITY_STATUS) = 'NONONONONO' then 'Did not provide'
			when eth.ETHNICITY_WHITE = 'Yes' then 'White'
			when eth.ETHNICITY_BLACK = 'Yes' then 'Black or Afican American'
			when eth.ETHNICITY_ASIAN = 'Yes' then 'Asian'
			when eth.ETHNICITY_INDIAN = 'Yes' then 'American Indian or Alaska Native'
			when eth.ETHNICITY_HAWAIIAN = 'Yes' then 'Native Hawaiian or other Pacific Islander'
			else null
		end
	else null
	end race
from
(
select subs.submission_id 
  , subs.person_id
  , case 
	when nvl(hsp.ETHNICITY_Y,'No') = 'Yes' then 'I am Hispanic or Latino'
	else null
	end as ETHNICITY
  , nvl(wht.ETHNICITY_Y,'No')||nvl(blk.ETHNICITY_Y,'No')||nvl(asn.ETHNICITY_Y,'No')||nvl(hwn.ETHNICITY_Y,'No')||nvl(ind.ETHNICITY_Y,'No') as ETHNICITY_STATUS
  , nvl(hsp.ETHNICITY_Y,'No') as ETHNICITY_HISPANIC
  , nvl(wht.ETHNICITY_Y,'No') as ETHNICITY_WHITE
  , nvl(blk.ETHNICITY_Y,'No') as ETHNICITY_BLACK
  , nvl(asn.ETHNICITY_Y,'No') as ETHNICITY_ASIAN
  , nvl(ind.ETHNICITY_Y,'No') as ETHNICITY_INDIAN
  , nvl(hwn.ETHNICITY_Y,'No') as ETHNICITY_HAWAIIAN
  , nvl(unk.ETHNICITY_Y,'No') as ETHNICITY_UNKNOWN
from IRC_SUBMISSIONS SUBS
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '1') wht on subs.person_id = wht.person_id
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '2') unk on subs.person_id = unk.person_id
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '3') blk on subs.person_id = blk.person_id
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '4') hsp on subs.person_id = hsp.person_id
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '5') asn on subs.person_id = asn.person_id
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '6') hwn on subs.person_id = hwn.person_id
left join (
SELECT PERSON_ID
  , 'Yes' as ETHNICITY_Y
FROM PER_ETHNICITIES
WHERE ETHNICITY = '7') ind on subs.person_id = ind.person_id) ETH) ETHN



where 1=1
and req.requisition_id = title.requisition_id
and req.current_phase_id = req_phase.phase_id
and req.current_state_id = req_state.state_id
and req.department_id = dept.organization_id
and req.requisition_id = sub.requisition_id
and sub.current_phase_id = sub_phase.phase_id
and sub.current_state_id = sub_state.state_id
and sub.person_id = cand.person_id
and sub.submission_id = hist.submission_id(+)
and sub.current_state_id = hist.state_id(+)
and hist.reason_id = reas.reason_id(+)
and req.requisition_id = strack.requisition_id(+)
and sub.submission_id = strack.submission_id(+)
and cand.candidate_number = strack.candidate_number(+)
and strack.dimension_id = sname.dimension_id(+)
and strack.site_number = cxsite.site_number(+)
and cand.person_id = pname.person_id(+)
and sub.submission_id = attr.submission_id(+)
and cand.person_id = attr.person_id(+)
and cand.person_id = vets.person_id(+)
and sub.submission_id = ethn.submission_id(+)
and cand.person_id = ethn.person_id(+)
and req.REQUISITION_NUMBER = :P_REQ_NUMBER
--and (title.REQUISITION_NAME in (:P_REQ_NAME) or coalesce(:P_REQ_NAME,'ALL')='ALL')
--and (req_phase.PHASE_NAME|| ' - ' ||req_state.STATE_NAME in (:P_REQ_STATUS) or coalesce(:P_REQ_STATUS,'ALL')='ALL')
order by req.REQUISITION_NUMBER
  , pname.CANDIDATE_NAME