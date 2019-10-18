# frozen_string_literal: true

class SentenceType
  DETERMINATE = :determinate
  INDETERMINATE = :indeterminate
  RECALL = :recall
  NON_RECALL = :non_recall

  attr_reader :code, :description, :duration_type, :recall_status

  def initialize(imprisonment_status)
    @code = imprisonment_status
    @code = 'UNK_SENT' if @code.nil?

    @description, @duration_type, @recall_status = SENTENCE_TYPES.fetch(@code)
  end

  def indeterminate_sentence?
    duration_type == INDETERMINATE
  end

  def recall_sentence?
    recall_status == RECALL
  end

  def civil?
    %w[
      CIVIL
      CIVIL_CON
      YOC_CONT
      CIVIL_DT
      A_CFINE
      YO_CFINE
      CIV_RMD
    ].include? code
  end
end

SENTENCE_TYPES = {
  'IPP' => ['Indeterminate Sent for Public Protection', :indeterminate, :non_recall],
  'LIFE' => ['Serving Life Imprisonment', :indeterminate, :non_recall],
  'HMPL' => ['Detention During Her Majesty\'s Pleasure', :indeterminate, :non_recall],
  'ALP' => ['Automatic', :indeterminate, :non_recall],
  'DFL' => ['Detention For Life - Under 18', :indeterminate, :non_recall],
  'DLP' => ['Adult Discretionary', :indeterminate, :non_recall],
  'DPP' => ['Detention For Public Protection', :indeterminate, :non_recall],
  'MLP' => ['Adult Mandatory Life', :indeterminate, :non_recall],
  'LR_LIFE' => ['Recall to Custody Indeterminate Sentence', :indeterminate, :recall],
  'LR_IPP' => ['Licence recall from IPP Sentence', :indeterminate, :recall],
  'LR_EPP' => ['Licence recall from EPP Sentence', :determinate, :recall],
  'LR_DPP' => ['Licence recall from DPP Sentence', :indeterminate, :recall],
  'CFLIFE' => ['Custody for life S8 CJA82 (18-21 Yrs)', :determinate, :non_recall],
  'SEC90' => ['Life - Murder Under 18', :determinate, :non_recall],
  'SEC90_03' => ['Life - Murder Under 18 CJA03', :determinate, :non_recall],
  'SEC93' => ['Custody For Life - Under 21', :indeterminate, :non_recall],
  'SEC93_03' => ['Custody For Life - Under 21 CJA03', :indeterminate, :non_recall],
  'SEC94' => ['Custody Life (18-21 Years Old)', :indeterminate, :non_recall],
  'EXSENT' => ['Extended Sentence CJA91', :determinate, :non_recall],
  'EXSENT03' => ['Extended Sentence CJA03', :determinate, :non_recall],
  'EXSENT08' => ['Extended Sentence CJ&I Act 2008', :determinate, :non_recall],
  'LR_ES' => ['Recalled to Prison frm Extended Sentence', :determinate, :recall],
  'SENT_EXL' => ['Sentenced - Extended Licence', :determinate, :non_recall],
  'CUSTPLUS' => ['Custody Plus Sentence', :determinate, :non_recall],
  'INT_CUST' => ['Intermittent Custody', :determinate, :non_recall],
  'SENT' => ['Adult Imprisonment Without Option', :determinate, :non_recall],
  'SENT03' => ['Adult Imprisonment Without Option CJA03', :determinate, :non_recall],
  'CJCON08' => ['Adult Imprisonment Release Conversion', :determinate, :non_recall],
  'LR' => ['Recalled to Prison from Parole (Non HDC)', :determinate, :recall],
  'FTR/08' => ['Fixed Term Recall CJ&I Act 2008', :determinate, :recall],
  'LR_HDC' => ['Recalled to Prison breach HDC Conditions', :determinate, :recall],
  'BOAR' => ['Breach Of At Risk CJA 1991', :determinate, :non_recall],
  'S47MHA' => ['Home Sec Order to Psych Hosp (SENT)', :determinate, :non_recall],
  'CRIM_CON' => ['Criminal Contempt', :determinat, :non_recall],
  'SEC91' => ['Serious Offence -18 POCCA 2000', :determinate, :non_recall],
  'SEC91_03' => ['Serious Offence -18 CJA03 POCCA 2000', :determinate, :non_recall],
  'YOI' => ['Detention In Young Offender Institution', :determinate, :non_recall],
  'REFER' => ['DTO_YOI Referal', :determinate, :non_recall],
  'DTO' => ['Detention Training Order', :determinate, :non_recall],
  'LR_YOI' => ['Recalled to YOI from fixed sentence', :determinate, :recall],
  'UNK_SENT' => ['Unknown Sentenced', :determinate, :non_recall],
  'A_FINE' => ['Adult Imprisonment In Default Of Fine', :determinate, :non_recall],
  'AFIXED' => ['Adult Imprisonment - Fixed Penalty', :determinate, :non_recall],
  'YOFINE' => ['Detention (Young Offender) Fine Payment', :determinate, :non_recall],
  'YOFIXED' => ['Y O Imprisonment - Fixed Penalty', :determinate, :non_recall],
  'A_FINE1' => ['Adult Imprisonment Fine Payment (Time)', :determinate, :non_recall],
  'A_FINE2' => ['Adult Imprisonment Fine Payment No Time', :determinate, :non_recall],
  'JR' => ['Conv - Judgement Respited', :determinate, :non_recall],
  'SEC38' => ['Convicted_Committed to Crown Court', :determinate, :non_recall],
  'SEC37' => ['Conv - YO Comm to CC for Sentence', :determinate, :non_recall],
  'SEC39' => ['Convicted_Remitted to Magistrates Court', :determinate, :non_recall],
  'S41MHA' => ['Conv - Hospital Order with Restrictions', :determinate, :non_recall],
  'S45MHA' => ['Conv. Hosp. Direction Sec45A MHA 83', :determinate, :non_recall],
  'S37MHA' => ['Removal to Psych. Hosp under order', :determinate, :non_recall],
  'UNK_CONV' => ['Unknown Convicted and Unsentenced', :determinate, :non_recall],
  'SEC56' => ['Conv - Breached Non-Cust Alternatives', :determinate, :non_recall],
  'S43MHA' => ['Conv-Comm to CC for Order (Restrictions)', :determinate, :non_recall],
  'SEC43' => ['Committed to Crown Court Sec43MHA 1983', :determinate, :non_recall],
  'SEC42' => ['Conv -Comm to CC For Sentence 1973 Act', :determinate, :non_recall],
  'SEC24_2A' => ['Conv - Comm to CC Breach Susp. Sent', :determinate, :non_recall],
  'SEC19_3B' => ['Conv-Comm to CC Breach Attendance Order', :determinate, :non_recall],
  'SEC18_2' => ['Conv - Comm to cc Revoke amend CSO', :determinate, :non_recall],
  'SEC17_3' => ['Conv - Breach Of CSO - CJA 1972', :determinate, :non_recall],
  'SEC8_6' => ['Conv-comm to cc breached PO new offence', :determinate, :non_recall],
  'SEC6_4' => ['Conv-Comm to CC Breach PO Requirements', :determinate, :non_recall],
  'SEC6B' => ['Conv - Comm to CC Breached Bail', :determinate, :non_recall],
  'SEC45' => ['Conv - Awaiting Social Inquiry Reports', :determinate, :non_recall],
  'S38MHA' => ['Conv-Await Removal to Hosp interim order', :determinate, :non_recall],
  'SEC5' => ['Conv Under Sec5 Vagrancy Act 1824', :determinate, :non_recall],
  'SEC30' => ['Conv - Awaiting Medical Reports MCA 1980', :determinate, :non_recall],
  'SEC10_3' => ['Conv - Adjourned For Reports MCA 1980', :determinate, :non_recall],
  'SEC2_1' => ['Conv - YO Awaiting Reports CJA 1982', :determinate, :non_recall],
  'CIVIL' => ['Civil Committal (Adult)', :determinate, :non_recall],
  'CIVIL_CON' => ['Adult Civil Contempt', :determinate, :non_recall],
  'YOC_CONT' => ['Y O Civil Contempt', :determinate, :non_recall],
  'CIVIL_DT' => ['Civil Committal Detention 17-20 year old', :determinate, :non_recall],
  'A_CFINE' => ['Civil Prisoner Fine (Adult)', :determinate, :non_recall],
  'YO_CFINE' => ['Civil Prisoner Fine (Young Offender)', :determinate, :non_recall],
  'DEPORT' => ['Awaiting Deportation Only', :determinate, :non_recall],
  'EXTRAD' => ['Awaiting Extradition Only', :determinate, :non_recall],
  'DET' => ['Immigration Detainee', :determinate, :non_recall],
  'TRL' => ['Committed to Crown Court for Trial', :determinate, :non_recall],
  'S48MHA' => ['Psychiatric Hospital from Prison (RX)', :determinate, :non_recall],
  'S36MHA' => ['Remand to Psychiatric Hospital by CC', :determinate, :non_recall],
  'S35MHA' => ['Remanded to Psychiatric Hosp by CC or MC', :determinate, :non_recall],
  'CIV_RMD' => ['Civil Remand Family Law Act 1996', :determinate, :non_recall],
  'RX' => ['Remanded to Magistrates Court', :determinate, :non_recall],
  'REC_DEP' => ['Recommended For Deportation', :determinate, :non_recall],
  'UNK_CUST' => ['Unknown Custodial Undisposed', :determinate, :non_recall],
  'DISCHARGED' => ['Freed On The Rising Of The Court', :determinate, :non_recall],
  'POLICE' => ['In Police Cells (not police remand)', :determinate, :non_recall],
  'SUSP_SEN' => ['Suspended Sentence', :determinate, :non_recall],
  'DTTO' => ['Drug Treatment and Testing Order', :determinate, :non_recall],
  'SUP_ORD' => ['Supervision Order', :determinate, :non_recall],
  'REST_ORD' => ['Restriction Order Attending Football', :determinate, :non_recall],
  'NON-CUST' => ['Non Custodial Punishment', :determinate, :non_recall],
  'DEF_SENT' => ['Deferred Sentence', :determinate, :non_recall],
  'UNFIT' => ['Unfit To Plead', :determinate, :non_recall],
  'DISCONT' => ['Case Withdrawn Or Not Tried', :determinate, :non_recall],
  'SINE DIE' => ['Adjourned Sine Die - To Lie On File', :determinate, :non_recall],
  'BOBC' => ['Breach of Bail Conditions - FTA', :determinate, :non_recall],
  'UNKNOWN' => ['Disposal Not Known', :determinate, :non_recall],
  'DIED' => ['Died', :determinate, :non_recall],
  'LASPO_AR' => ['EDS LASPO Automatic Release', :determinate, :non_recall],
  'LR_LASPO_AR' => ['LR - EDS LASPO Automatic Release', :determinate, :recall],
  'LASPO_DR' => ['EDS LASPO Discretionary Release', :determinate, :non_recall],
  'LR_LASPO_DR' => ['LR - EDS LASPO Discretionary Release', :determinate, :recall],
  'FTR_HDC' => ['Fixed Term Recall while on HDC', :determinate, :recall],
  'LR_MLP' => ['Recall to Custody Mandatory Life', :indeterminate, :recall],
  'LR_ALP' => ['Recall from Automatic Life', :indeterminate, :recall],
  'LR_DLP' => ['Recall from Discretionary Life', :indeterminate, :recall],
  'ALP_LASPO' => ['Automatic Life Sec 224A 03', :indeterminate, :non_recall],
  'LR_ALP_LASPO' => ['Recall from Automatic Life Sec 224A 03', :indeterminate, :recall],
  'FTR_SCH15' => ['FTR Schedule 15 Offender', :determinate, :recall],
  'ADIMP_ORA' => ['ORA CJA03 Standard Determinate Sentence', :determinate, :non_recall],
  'CUR_ORA' => ['ORA Recalled from Curfew Conditions', :determinate, :recall],
  'DTO_ORA' => ['ORA Detention and Training Order', :determinate, :non_recall],
  'FTR_ORA' => ['ORA 28 Day Fixed Term Recall', :determinate, :recall],
  'FTR_HDC_ORA' => ['ORA Fixed Term Recall while on HDC', :determinate, :recall],
  'FTRSCH15_ORA' => ['ORA FTR Schedule 15 Offender', :determinate, :recall],
  'HDR_ORA' => ['ORA HDC Recall (not curfew violation)', :determinate, :recall],
  'LR_ORA' => ['ORA Licence Recall', :determinate, :recall],
  'SEC91_03_ORA' => ['ORA Serious Offence -18 CJA03 POCCA 2000', :determinate, :non_recall],
  'YOI_ORA' => ['ORA Young Offender Institution', :determinate, :non_recall],
  'BOTUS' => ['ORA Breach Top Up Supervision', :determinate, :non_recall],
  '14FTR_ORA' => ['ORA 14 Day Fixed Term Recall', :determinate, :recall],
  'LR_YOI_ORA' => ['Recall from YOI', :determinate, :recall],
  'LR_SEC91_ORA' => ['Recall Serious Off -18 CJA03 POCCA 2000', :determinate, :recall],
  '14FTRHDC_ORA' => ['14 Day Fixed Term Recall from HDC', :determinate, :recall],
  'SEC236A' => ['Section 236A SOPC CJA03', :determinate, :non_recall],
  'LR_SEC236A' => ['LR - Section 236A SOPC CJA03', :determinate, :recall]
}
