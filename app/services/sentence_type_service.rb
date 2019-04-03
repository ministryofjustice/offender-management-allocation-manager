class SentenceTypeService
  def self.indeterminate_sentence?(sentence_type)
    SentenceType.create(sentence_type).duration_type ==
      SentenceType::INDETERMINATE
  end

  def self.describe_sentence(sentence_type)
    SentenceType.create(sentence_type).description
  end
end
