# frozen_string_literal: true

class SentenceType
  DETERMINATE = :determinate
  INDETERMINATE = :indeterminate

  attr_reader :code, :description

  def initialize(imprisonment_status)
    @code = imprisonment_status
    @code = 'UNK_SENT' if @code.nil?

    @description, @duration_type, = SENTENCE_TYPES.fetch(@code)
  end

  def immigration_case?
    @code == 'DET'
  end

  def indeterminate_sentence?
    @duration_type == INDETERMINATE
  end

  def criminal_sentence?
    !civil_sentence?
  end

  def civil_sentence?
    %w[
      CIVIL
      CIVIL_CON
      YOC_CONT
      CIVIL_DT
      A_CFINE
      YO_CFINE
      CIV_RMD
    ].include? @code
  end
end

SENTENCE_TYPES = {
  'IPP' => ['Indeterminate Sent for Public Protection', :indeterminate],
  'LIFE' => ['Serving Life Imprisonment', :indeterminate],
  'HMPL' => ['Detention During Her Majesty\'s Pleasure', :indeterminate],
  'ALP' => ['Automatic', :indeterminate],
  'DFL' => ['Detention For Life - Under 18', :indeterminate],
  'DLP' => ['Adult Discretionary', :indeterminate],
  'DPP' => ['Detention For Public Protection', :indeterminate],
  'MLP' => ['Adult Mandatory Life', :indeterminate],
  'LR_LIFE' => ['Recall to Custody Indeterminate Sentence', :indeterminate],
  'LR_IPP' => ['Licence recall from IPP Sentence', :indeterminate],
  'LR_EPP' => ['Licence recall from EPP Sentence', :determinate],
  'LR_DPP' => ['Licence recall from DPP Sentence', :indeterminate],
  'CFLIFE' => ['Custody for life S8 CJA82 (18-21 Yrs)', :determinate],
  'SEC90' => ['Life - Murder Under 18', :determinate],
  'SEC90_03' => ['Life - Murder Under 18 CJA03', :determinate],
  'SEC93' => ['Custody For Life - Under 21', :indeterminate],
  'SEC93_03' => ['Custody For Life - Under 21 CJA03', :indeterminate],
  # 2020 version of SEC93_03
  'SEC275' => ['Custody For Life Sec 275 2020 Murder U21', :indeterminate],
  'SEC94' => ['Custody Life (18-21 Years Old)', :indeterminate],
  # 2020 version of SEC94
  'SEC272' => ['Custody For Life Sec 272 2020 (18-20)', :indeterminate],
  'EXSENT' => ['Extended Sentence CJA91', :determinate],
  'EXSENT03' => ['Extended Sentence CJA03', :determinate],
  'EXSENT08' => ['Extended Sentence CJ&I Act 2008', :determinate],
  'LR_ES' => ['Recalled to Prison frm Extended Sentence', :determinate],
  'SENT_EXL' => ['Sentenced - Extended Licence', :determinate],
  'CUSTPLUS' => ['Custody Plus Sentence', :determinate],
  'INT_CUST' => ['Intermittent Custody', :determinate],
  'SENT' => ['Adult Imprisonment Without Option', :determinate],
  'SENT03' => ['Adult Imprisonment Without Option CJA03', :determinate],
  'CJCON08' => ['Adult Imprisonment Release Conversion', :determinate],
  'LR' => ['Recalled to Prison from Parole (Non HDC)', :determinate],
  'FTR/08' => ['Fixed Term Recall CJ&I Act 2008', :determinate],
  'LR_HDC' => ['Recalled to Prison breach HDC Conditions', :determinate],
  'BOAR' => ['Breach Of At Risk CJA 1991', :determinate],
  'S47MHA' => ['Home Sec Order to Psych Hosp (SENT)', :determinate],
  'CRIM_CON' => ['Criminal Contempt', :determinate],
  'SEC91' => ['Serious Offence -18 POCCA 2000', :determinate],
  'SEC91_03' => ['Serious Offence -18 CJA03 POCCA 2000', :determinate],
  # 2020 version of SEC91_03
  'SEC250' => ['Recall Serious Offence Sec 250 2020 U18', :determinate],
  'YOI' => ['Detention In Young Offender Institution', :determinate],
  'REFER' => ['DTO_YOI Referal', :determinate],
  'DTO' => ['Detention Training Order', :determinate],
  'LR_YOI' => ['Recalled to YOI from fixed sentence', :determinate],
  'UNK_SENT' => ['Unknown Sentenced', :determinate],
  'A_FINE' => ['Adult Imprisonment In Default Of Fine', :determinate],
  'AFIXED' => ['Adult Imprisonment - Fixed Penalty', :determinate],
  'YOFINE' => ['Detention (Young Offender) Fine Payment', :determinate],
  'YOFIXED' => ['Y O Imprisonment - Fixed Penalty', :determinate],
  'A_FINE1' => ['Adult Imprisonment Fine Payment (Time)', :determinate],
  'A_FINE2' => ['Adult Imprisonment Fine Payment No Time', :determinate],
  'JR' => ['Conv - Judgement Respited', :determinate],
  'SEC38' => ['Convicted_Committed to Crown Court', :determinate],
  'SEC37' => ['Conv - YO Comm to CC for Sentence', :determinate],
  'SEC39' => ['Convicted_Remitted to Magistrates Court', :determinate],
  'S41MHA' => ['Conv - Hospital Order with Restrictions', :determinate],
  'S45MHA' => ['Conv. Hosp. Direction Sec45A MHA 83', :determinate],
  'S37MHA' => ['Removal to Psych. Hosp under order', :determinate],
  'UNK_CONV' => ['Unknown Convicted and Unsentenced', :determinate],
  'SEC56' => ['Conv - Breached Non-Cust Alternatives', :determinate],
  'S43MHA' => ['Conv-Comm to CC for Order (Restrictions)', :determinate],
  'SEC43' => ['Committed to Crown Court Sec43MHA 1983', :determinate],
  'SEC42' => ['Conv -Comm to CC For Sentence 1973 Act', :determinate],
  'SEC24_2A' => ['Conv - Comm to CC Breach Susp. Sent', :determinate],
  'SEC19_3B' => ['Conv-Comm to CC Breach Attendance Order', :determinate],
  'SEC18_2' => ['Conv - Comm to cc Revoke amend CSO', :determinate],
  'SEC17_3' => ['Conv - Breach Of CSO - CJA 1972', :determinate],
  'SEC8_6' => ['Conv-comm to cc breached PO new offence', :determinate],
  'SEC6_4' => ['Conv-Comm to CC Breach PO Requirements', :determinate],
  'SEC6B' => ['Conv - Comm to CC Breached Bail', :determinate],
  'SEC45' => ['Conv - Awaiting Social Inquiry Reports', :determinate],
  'S38MHA' => ['Conv-Await Removal to Hosp interim order', :determinate],
  'SEC5' => ['Conv Under Sec5 Vagrancy Act 1824', :determinate],
  'SEC30' => ['Conv - Awaiting Medical Reports MCA 1980', :determinate],
  'SEC10_3' => ['Conv - Adjourned For Reports MCA 1980', :determinate],
  'SEC2_1' => ['Conv - YO Awaiting Reports CJA 1982', :determinate],
  'CIVIL' => ['Civil Committal (Adult)', :determinate],
  'CIVIL_CON' => ['Adult Civil Contempt', :determinate],
  'YOC_CONT' => ['Y O Civil Contempt', :determinate],
  'CIVIL_DT' => ['Civil Committal Detention 17-20 year old', :determinate],
  'A_CFINE' => ['Civil Prisoner Fine (Adult)', :determinate],
  'YO_CFINE' => ['Civil Prisoner Fine (Young Offender)', :determinate],
  'DEPORT' => ['Awaiting Deportation Only', :determinate],
  'EXTRAD' => ['Awaiting Extradition Only', :determinate],
  'DET' => ['Immigration Detainee', :determinate],
  'TRL' => ['Committed to Crown Court for Trial', :determinate],
  'S48MHA' => ['Psychiatric Hospital from Prison (RX)', :determinate],
  'S36MHA' => ['Remand to Psychiatric Hospital by CC', :determinate],
  'S35MHA' => ['Remanded to Psychiatric Hosp by CC or MC', :determinate],
  'CIV_RMD' => ['Civil Remand Family Law Act 1996', :determinate],
  'RX' => ['Remanded to Magistrates Court', :determinate],
  'REC_DEP' => ['Recommended For Deportation', :determinate],
  'UNK_CUST' => ['Unknown Custodial Undisposed', :determinate],
  'DISCHARGED' => ['Freed On The Rising Of The Court', :determinate],
  'POLICE' => ['In Police Cells (not police remand)', :determinate],
  'SUSP_SEN' => ['Suspended Sentence', :determinate],
  'DTTO' => ['Drug Treatment and Testing Order', :determinate],
  'SUP_ORD' => ['Supervision Order', :determinate],
  'REST_ORD' => ['Restriction Order Attending Football', :determinate],
  'NON-CUST' => ['Non Custodial Punishment', :determinate],
  'DEF_SENT' => ['Deferred Sentence', :determinate],
  'UNFIT' => ['Unfit To Plead', :determinate],
  'DISCONT' => ['Case Withdrawn Or Not Tried', :determinate],
  'SINE DIE' => ['Adjourned Sine Die - To Lie On File', :determinate],
  'BOBC' => ['Breach of Bail Conditions - FTA', :determinate],
  'UNKNOWN' => ['Disposal Not Known', :determinate],
  'DIED' => ['Died', :determinate],
  'LASPO_AR' => ['EDS LASPO Automatic Release', :determinate],
  'LR_LASPO_AR' => ['LR - EDS LASPO Automatic Release', :determinate],
  'LASPO_DR' => ['EDS LASPO Discretionary Release', :determinate],
  # 2020 versions of LASPO_DR (6 of)
  'LR_EDS18' => ['LR - EDS Sec 266 2020 (18-20)', :determinate],
  'LR_EDS21' => ['LR - EDS Sec 279 2020 (21+)', :determinate],
  'LR_EDSU18' => ['LR - EDS Sec 254 2020 (U18)', :determinate],
  'EDS18' => ['EDS Sec 266 2020 (18-20)', :determinate],
  'EDS21' => ['EDS Sec 266 2020 (21+)', :determinate],
  'EDSU18' => ['EDS Sec 254 2020 (U18)', :determinate],
  'LR_LASPO_DR' => ['LR - EDS LASPO Discretionary Release', :determinate],
  'FTR_HDC' => ['Fixed Term Recall while on HDC', :determinate],
  'LR_MLP' => ['Recall to Custody Mandatory Life', :indeterminate],
  'LR_ALP' => ['Recall from Automatic Life', :indeterminate],
  'LR_DLP' => ['Recall from Discretionary Life', :indeterminate],
  'ALP_LASPO' => ['Automatic Life Sec 224A 03', :indeterminate],
  # 2020 verskions of ALP_LASPO
  'ALP_CODE18' => ['Automatic Life Sec 273 2020 (18-20)', :indeterminate],
  'ALP_CODE21' => ['Automatic Life Sec 273 2020 (21+)', :indeterminate],
  'LR_ALP_LASPO' => ['Recall from Automatic Life Sec 224A 03', :indeterminate],
  # 2020 versions of LR_ALP_LASPO
  'LR_ALP_CDE18' => ['Recall Auto. Life Sec 273 2020 (18-20)', :indeterminate],
  'LR_ALP_CDE21' => ['Recall Auto. Life Sec 283 2020 (21+)', :indeterminate],
  'FTR_SCH15' => ['FTR Schedule 15 Offender', :determinate],
  # 2020 version of FTR_SCH15
  'FTRSCH18' => ['FTR Sch 18 2020 Offender', :determinate],
  'ADIMP_ORA' => ['ORA CJA03 Standard Determinate Sentence', :determinate],
  # 2020 version of ADIMP_ORA
  'ADIMP_ORA20' => ['ORA 2020 Standard Determinate Sentence', :determinate],
  'CUR_ORA' => ['ORA Recalled from Curfew Conditions', :determinate],
  'DTO_ORA' => ['ORA Detention and Training Order', :determinate],
  'FTR_ORA' => ['ORA 28 Day Fixed Term Recall', :determinate],
  'FTR_HDC_ORA' => ['ORA Fixed Term Recall while on HDC', :determinate],
  'FTRSCH15_ORA' => ['ORA FTR Schedule 15 Offender', :determinate],
  # 2020 version of FTRSCH15_ORA
  'FTRSCH18_ORA' => ['ORA FTR Sch 18 2020 Offender', :determinate],
  'HDR_ORA' => ['ORA HDC Recall (not curfew violation)', :determinate],
  'LR_ORA' => ['ORA Licence Recall', :determinate],
  'SEC91_03_ORA' => ['ORA Serious Offence -18 CJA03 POCCA 2000', :determinate],
  # 2020 version of SEC91_03_ORA
  'SEC250_ORA' => ['ORA Serious Offence Sec 250 2020 U18', :determinate],
  'YOI_ORA' => ['ORA Young Offender Institution', :determinate],
  'BOTUS' => ['ORA Breach Top Up Supervision', :determinate],
  '14FTR_ORA' => ['ORA 14 Day Fixed Term Recall', :determinate],
  'LR_YOI_ORA' => ['Recall from YOI', :determinate],
  'LR_SEC91_ORA' => ['Recall Serious Off -18 CJA03 POCCA 2000', :determinate],
  'LR_SEC250' => ['Recall Serious Offence Sec 250 2020 (U18)', :determinate],
  '14FTRHDC_ORA' => ['14 Day Fixed Term Recall from HDC', :determinate],
  'SEC236A' => ['Section 236A SOPC CJA03', :determinate],
  # 2020 versions of SEC236A
  'SOPC18' => ['SOPC Sec 265 2020 (18-20)', :determinate],
  'SOPC21' => ['SOPC Sec 265 2020 (21+)', :determinate],
  'LR_SEC236A' => ['LR - Section 236A SOPC CJA03', :determinate],
  # 2020 versions of LR_SEC236A
  'LR_SOPC18' => ['LR - SOPC Sec 265 2020 (18-20)', :determinate],
  'LR_SOPC21' => ['LR - SOPC Sec 265 2020 (21+)', :determinate],
}.freeze
