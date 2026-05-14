# frozen_string_literal: true

class SentenceType
  # Source of truth for recall sentence types:
  # https://github.com/ministryofjustice/prison-api/blob/main/src/main/java/uk/gov/justice/hmpps/prison/api/model/SentenceTypeRecallType.kt
  # Keep this list aligned exactly with the upstream enum until we can rely on upstream `recall` attribute again.
  RECALL_SENTENCE_TYPES = %w[
    14FTR_ORA
    CUR
    CUR_ORA
    FTR
    FTRSCH15_ORA
    FTRSCH18
    FTRSCH18_ORA
    FTR_14_HDC_ORA
    FTR_56ORA
    FTR_HDC
    FTR_HDC_ORA
    FTR_ORA
    FTR_SCH15
    HDR
    HDR_ORA
    LR
    LRSEC250_ORA
    LR_ALP
    LR_ALP_CDE18
    LR_ALP_CDE21
    LR_ALP_LASPO
    LR_DLP
    LR_DPP
    LR_EDS18
    LR_EDS21
    LR_EDSU18
    LR_EPP
    LR_ES
    LR_IPP
    LR_LASPO_AR
    LR_LASPO_DR
    LR_LIFE
    LR_MLP
    LR_ORA
    LR_SEC236A
    LR_SEC91_ORA
    LR_SOPC18
    LR_SOPC21
    LR_YOI_ORA
  ].freeze

  CIVIL_SENTENCE_TYPES = %w[
    A/FINE
    A_FINE
    A_CFINE
    CIVIL
    CIVIL_CON
    CIVIL_DT
    CIV_RMD
    YOC_CONT
    YO_CFINE
  ].freeze

  attr_reader :code

  def initialize(imprisonment_status)
    @code = imprisonment_status
    @code = 'UNK_SENT' if @code.nil?
  end

  def immigration_case?
    @code == 'DET'
  end

  def criminal_sentence?
    !civil_sentence?
  end

  def recall?
    RECALL_SENTENCE_TYPES.include?(@code)
  end

  def civil_sentence?
    CIVIL_SENTENCE_TYPES.include?(@code)
  end
end
