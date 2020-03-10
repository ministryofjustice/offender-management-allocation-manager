# frozen_string_literal: true

module Nomis
  class SentenceDetail
    include Deserialisable

    attr_accessor :first_name, :last_name,
                  :home_detention_curfew_eligibility_date,
                  :home_detention_curfew_actual_date,
                  :parole_eligibility_date,
                  :post_recall_release_date,
                  :post_recall_release_override_date,
                  :release_date,
                  :sentence_start_date,
                  :tariff_date

    attr_writer :automatic_release_date,
                :automatic_release_override_date,
                :conditional_release_date,
                :conditional_release_override_date

    def automatic_release_date
      @automatic_release_override_date.presence || @automatic_release_date
    end

    def conditional_release_date
      @conditional_release_override_date.presence || @conditional_release_date
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
      return nil if dates.empty?

      past_dates = []
      future_dates = []

      dates.each do |date|
        if date >= Time.zone.today
          future_dates << date
        else
          past_dates << date
        end
      end

      future_dates.present? ? future_dates.min.to_date : past_dates.min.to_date
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    # rubocop:disable Metrics/MethodLength
    def self.from_json(payload)
      SentenceDetail.new.tap { |obj|
        obj.first_name = payload['firstName']
        obj.last_name = payload['lastName']

        obj.parole_eligibility_date = deserialise_date(payload, 'paroleEligibilityDate')
        obj.release_date = deserialise_date(payload, 'releaseDate')
        obj.sentence_start_date = deserialise_date(payload, 'sentenceStartDate')
        obj.tariff_date = deserialise_date(payload, 'tariffDate')
        obj.automatic_release_date = deserialise_date(payload, 'automaticReleaseDate')
        obj.post_recall_release_date = deserialise_date(payload, 'postRecallReleaseDate')
        obj.post_recall_release_override_date = deserialise_date(payload, 'postRecallReleaseOverrideDate')
        obj.conditional_release_date = deserialise_date(
          payload, 'conditionalReleaseDate'
        )
        obj.automatic_release_override_date = deserialise_date(
          payload, 'automaticReleaseOverrideDate'
        )
        obj.home_detention_curfew_eligibility_date = deserialise_date(
          payload, 'homeDetentionCurfewEligibilityDate'
        )
        obj.home_detention_curfew_actual_date = deserialise_date(
          payload, 'homeDetentionCurfewActualDate'
        )
        obj.conditional_release_override_date = deserialise_date(
          payload, 'conditionalReleaseOverrideDate'
        )
      }
    end
    # rubocop:enable Metrics/MethodLength
  end
end
