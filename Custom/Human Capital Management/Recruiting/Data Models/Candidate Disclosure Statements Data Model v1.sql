select req.REQUISITION_ID
  , sub.SUBMISSION_ID
  , sub.PERSON_ID
  , req.REQUISITION_NUMBER
  , title.REQUISITION_NAME
  , req_phase.PHASE_NAME|| ' - ' ||req_state.STATE_NAME as REQ_CURRENT_STATUS  
  , req.OPEN_DATE
  , cand.CANDIDATE_NUMBER
  , pname.CANDIDATE_NAME
/*
  , sub.HONORABLY
  , sub.SPOUSE
  , sub.UW_STATE
  , sub.SEX_CRIME
  , sub.MISDEMEANOR
  , sub.REGULATION
*/
from
/* REQUISITIONS */
(select REQUISITION_ID
  , REQUISITION_NUMBER
  , CURRENT_PHASE_ID
  , CURRENT_STATE_ID  
  , open_date
from IRC_REQUISITIONS_B
where REQ_USAGE_CODE = 'ORA_REQUISITION') REQ

/* REQUISITIONS TITLE*/
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

 /* SUBMISSION AND DISCLOSER DETAILS */
 , (select subs.SUBMISSION_ID
   , subs.REQUISITION_ID
   , subs.PERSON_ID
  /*
   , rhonor.HONORABLY
   , rspouse.SPOUSE
   , ruwstate.UW_STATE
   , rsexcrime.SEX_CRIME
   , rfelony.FELONY
   , rmisd.MISDEMEANOR
   , rpolicy.REGULATION  
  */
from 
(select SUBMISSION_ID
  , REQUISITION_ID
  , PERSON_ID
from IRC_SUBMISSIONS) subs
/*
 , (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as HONORABLY
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000293743041') rhonor

, (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as SPOUSE
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000293742939') rspouse

, (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as UW_STATE
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000293742814') ruwstate

, (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as SEX_CRIME
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000900824054') rsexcrime

, (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as FELONY
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000293743263') rfelony

, (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as MISDEMEANOR
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000293743258') rmisd

, (select PARTICIPANT_ID as PERSON_ID
  , QUESTION_ID
  , QUESTION_CODE
  , SUBJECT_ID as SUBMISSION_ID
  , LONG_TEXT as REGULATION
from HRQ_QSTNR_PCPT_RESPONSES_V
where SUBSCRIBER_ID = 4
and SUBJECT_CODE = 'SUBMISSION'
and STATUS = 'S'
and PARTICIPANT_TYPE = 'CANDIDATE'
and QUESTION_CODE = '300000293743050') rpolicy

where subs.submission_id = rhonor.submission_id
and subs.person_id = rhonor.person_id
and subs.submission_id = rspouse.submission_id
and subs.person_id = rspouse.person_id
and subs.submission_id = ruwstate.submission_id
and subs.person_id = ruwstate.person_id
and subs.submission_id = rsexcrime.submission_id
and subs.person_id = rsexcrime.person_id
and subs.submission_id = rfelony.submission_id
and subs.person_id = rfelony.person_id
and subs.submission_id = rmisd.submission_id
and subs.person_id = rmisd.person_id
and subs.submission_id = rpolicy.submission_id 
and subs.person_id = rpolicy.person_id
*/
) SUB

 /* CANDIDATE NUMBER */
, (select person_id
  , candidate_number
from IRC_CANDIDATES
order by candidate_number) CAND

/* CANDIDATE NAME  */
, (select person_id
  , full_name as CANDIDATE_NAME
from per_person_names_f
where name_type = 'GLOBAL'
and trunc(sysdate) between effective_start_date and effective_end_date) PNAME
 
where req.REQUISITION_ID = title.REQUISITION_ID
and req.current_phase_id = req_phase.phase_id
and req.current_state_id = req_state.state_id
and req.REQUISITION_ID = sub.REQUISITION_ID
and sub.person_id = cand.person_id
and cand.person_id = pname.person_id
and UPPER(req_phase.PHASE_NAME) = 'OPEN'
and (req.REQUISITION_NUMBER in (:P_REQ_NUMBER) or coalesce(:P_REQ_NUMBER,'ALL')='ALL')
and (title.REQUISITION_NAME in (:P_REQ_NAME) or coalesce(:P_REQ_NAME,'ALL')='ALL')
and (req_phase.PHASE_NAME|| ' - ' ||req_state.STATE_NAME in (:P_REQ_STATUS) or coalesce(:P_REQ_STATUS,'ALL')='ALL')
order by req.REQUISITION_NUMBER
  , pname.CANDIDATE_NAME