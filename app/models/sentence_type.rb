# frozen_string_literal: true

class SentenceType
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
