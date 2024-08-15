class Sentences::SentenceSequence
  def self.from(sentence_terms = [])
    sentence_terms
      .sort.uniq(&:comparable_fields)
      .group_by(&:case_id)
      .values.map { |terms| new(terms) }
  end

  def initialize(sentence_terms = [])
    @sentence_terms = sentence_terms
  end

  def sentence_start_date = @sentence_terms.first.sentence_start_date
  def duration = @sentence_terms.sum(&:duration)
  def indeterminate? = @sentence_terms.any?(&:indeterminate?)
end
