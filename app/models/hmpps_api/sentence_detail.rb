# frozen_string_literal: true

module HmppsApi
  class SentenceDetail
    attr_reader :actual_parole_date,
                :home_detention_curfew_actual_date,
                :home_detention_curfew_eligibility_date,
                :licence_expiry_date,
                :parole_eligibility_date,
                :recall,
                :release_date,
                :sentence_start_date,
                :tariff_date

    delegate :criminal_sentence?, :immigration_case?, :civil_sentence?, to: :@sentence_type

    # Note - this is hiding a defect - we never get sentence_expiry_date from NOMIS (but maybe we should?)
    attr_accessor :sentence_expiry_date

    def automatic_release_date
      @automatic_release_override_date.presence || @automatic_release_date
    end

    def conditional_release_date
      @conditional_release_override_date.presence || @conditional_release_date
    end

    def post_recall_release_date
      post_recall_release_date = nomis_post_recall_release_date

      return post_recall_release_date if @actual_parole_date.blank?

      return @actual_parole_date if post_recall_release_date.blank?

      if @actual_parole_date.before?(post_recall_release_date)
        @actual_parole_date
      else
        post_recall_release_date
      end
    end

    def nomis_post_recall_release_date
      @nomis_post_recall_release_override_date.presence || @nomis_post_recall_release_date
    end

    def earliest_release_date
      dates = [
        automatic_release_date,
        conditional_release_date,
        home_detention_curfew_actual_date,
        home_detention_curfew_eligibility_date,
        parole_eligibility_date,
        tariff_date
      ].compact

      if dates.empty?
        dates = [
          sentence_expiry_date,
          licence_expiry_date,
          post_recall_release_date,
          actual_parole_date].compact
      end

      past_dates, future_dates = dates.partition { |date| date < Time.zone.today }

      future_dates.any? ? future_dates.min.to_date : past_dates.max.try(:to_date)
    end

    def initialize(payload)
      @actual_parole_date = payload['actualParoleDate']&.to_date
      @automatic_release_date = payload['automaticReleaseDate']&.to_date
      @automatic_release_override_date = payload['automaticReleaseOverrideDate']&.to_date
      @conditional_release_date = payload['conditionalReleaseDate']&.to_date
      @conditional_release_override_date = payload['conditionalReleaseOverrideDate']&.to_date
      @home_detention_curfew_actual_date = payload['homeDetentionCurfewActualDate']&.to_date
      @home_detention_curfew_eligibility_date = payload['homeDetentionCurfewEligibilityDate']&.to_date
      @licence_expiry_date = payload['licenceExpiryDate']&.to_date
      @nomis_post_recall_release_date = payload['postRecallReleaseDate']&.to_date
      @nomis_post_recall_release_override_date = payload['postRecallReleaseOverrideDate']&.to_date
      @parole_eligibility_date = payload['paroleEligibilityDate']&.to_date
      @release_date = payload['releaseDate']&.to_date
      @sentence_start_date = payload['sentenceStartDate']&.to_date
      @tariff_date = payload['tariffDate']&.to_date

      @sentence_type = SentenceType.new payload.fetch('imprisonmentStatus', 'UNK_SENT')
      @recall = payload.fetch('recall', false)
      @indeterminate_sentence = payload['indeterminateSentence']
      @description = payload.fetch('imprisonmentStatusDescription', 'Unknown Sentenced')
    end

    def indeterminate_sentence?
      @indeterminate_sentence
    end

    def describe_sentence
      "#{@sentence_type.code} - #{@description}"
    end
  end
end
