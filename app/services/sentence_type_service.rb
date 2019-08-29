# frozen_string_literal: true

class SentenceTypeService
  def self.indeterminate_sentence?(sentence_type)
    SentenceType.create(sentence_type).duration_type ==
      SentenceType::INDETERMINATE
  end

  def self.recall_sentence?(sentence_type)
    SentenceType.create(sentence_type).recall_status ==
        SentenceType::RECALL
  end

  def self.describe_sentence(sentence_type)
    SentenceType.create(sentence_type).description
  end
end
