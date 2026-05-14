class Sentences::SentenceTerm::SentenceType < SimpleDelegator
  # Source of truth for indeterminate sentence types:
  # https://github.com/ministryofjustice/prison-api/blob/main/src/main/java/uk/gov/justice/hmpps/prison/api/model/SentenceTypeRecallType.kt
  # Keep this list aligned for now, we should evaluate using an API to get this info.
  INDETERMINATE_SENTENCE_TYPES = %w[
    20
    ALP
    ALP_CODE18
    ALP_CODE21
    ALP_LASPO
    DFL
    DLP
    DPP
    HMPL
    IPP
    LEGACY
    LIFE
    LIFE/IPP
    LR_ALP
    LR_ALP_CDE18
    LR_ALP_CDE21
    LR_ALP_LASPO
    LR_DLP
    LR_DPP
    LR_IPP
    LR_LIFE
    LR_MLP
    MLP
    SEC272
    SEC275
    SEC93
    SEC93_03
    SEC94
    ZMD
  ].freeze

  def indeterminate? = in?(INDETERMINATE_SENTENCE_TYPES)
end
