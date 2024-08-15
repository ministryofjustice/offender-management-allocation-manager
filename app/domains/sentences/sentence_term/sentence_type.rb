class Sentences::SentenceTerm::SentenceType < SimpleDelegator
  # Available Sentence Types, Sentence Descriptions
  # DLP           Adult Discretionary Life
  # MLP           Adult Mandatory Life
  # ALP           Automatic LIfe
  # ALP           Automatic Life
  # ADIMP         CJA03 Standard Determinate Sentence
  # EDS21         EDS Sec 279 Sentencing Code (21+)
  # EPP           Extended Sent Public Protection CJA 03
  # A/FINE        Imprisonment in Default of Fine
  # IPP           Indeterminate Sentence for the Public Protection
  # LEGACY        Legacy (pre 1991 Act)
  # LR            Licence Recall
  # LR_IPP        Licence recall from IPP Sentence
  # LIFE          Life Imprisonment or Detention S.53(1) CYPA 1933
  # LR_EDS21      LR EDS Sec 279 Sentencing Code (21+)
  # 14FTR_ORA     ORA 14 Day Fixed Term Recall
  # LR_ORA        ORA Licence Recall
  # ADIMP_ORA     ORA Sentencing Code Standard Determinate Sentence
  # LR_ALP        Recall from Automatic Life
  # LR_ALP_CDE21  Recall from Automatic Life Sec 283 Sentencing Code (21+)
  # LR_DLP        Recall from Discretionary Life
  # LR_LIFE       Recall to Custody Indeterminate Sentence
  # ADIMP         Sentencing Code Standard Determinate Sentence

  INDETERMINATE_SENTENCE_TYPES = [
    'IPP',
    'LR_IPP',
    'ALP',
    'LR_ALP',
    'ALP_CDE21',
    'LR_ALP_CDE21',
    'LIFE',
    'LR_LIFE',
    'DLP',
    'LR_DLP',
    'MLP',
    'LR_MLP'
  ].freeze

  def indeterminate? = in?(INDETERMINATE_SENTENCE_TYPES)
end
