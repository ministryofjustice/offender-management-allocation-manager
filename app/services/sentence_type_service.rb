class SentenceTypeService
  def self.determinate_sentence?(offender)
    SentenceType.for_offender(offender).duration_type == SentenceType::DETERMINATE
  end

  def self.describe_sentence(offender)
    SentenceType.for_offender(offender).description
  end
end
