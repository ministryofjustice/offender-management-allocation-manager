class Sentences
  def self.for(booking_id:)
    SentenceSequence.from(
      HmppsApi::PrisonApi::OffenderApi
        .get_offender_sentences_and_offences(booking_id)
        .map { |data| SentenceTerm.new(data) }
    )
  end
end
