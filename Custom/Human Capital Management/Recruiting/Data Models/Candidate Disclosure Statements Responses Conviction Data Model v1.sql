 /* SUBMISSION AND DISCLOSER DETAILS */
select subs.SUBMISSION_ID
   , subs.REQUISITION_ID
   , subs.PERSON_ID 
   , rsexcrime.SEX_CRIME
   , rfelony.FELONY
   , rmisd.MISDEMEANOR
   , rpolicy.REGULATION 
from 
(select SUBMISSION_ID
  , REQUISITION_ID
  , PERSON_ID
from IRC_SUBMISSIONS) subs

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
and QUESTION_CODE = '300000293743272') rsexcrime

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

where subs.submission_id = rsexcrime.submission_id(+)
and subs.person_id = rsexcrime.person_id(+)
and subs.submission_id = rfelony.submission_id(+)
and subs.person_id = rfelony.person_id(+)
and subs.submission_id = rmisd.submission_id(+)
and subs.person_id = rmisd.person_id(+)
and subs.submission_id = rpolicy.submission_id (+)
and subs.person_id = rpolicy.person_id(+)