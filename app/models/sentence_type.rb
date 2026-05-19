# frozen_string_literal: true

class SentenceType
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

  def civil_sentence?
    CIVIL_SENTENCE_TYPES.include?(@code)
  end
end
