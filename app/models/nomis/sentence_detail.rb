# frozen_string_literal: true

module Nomis
  class SentenceDetail
    include Deserialisable

    attr_accessor :first_name, :last_name

    attr_reader :home_detention_curfew_eligibility_date,
                :home_detention_curfew_actual_date,
                :parole_eligibility_date,
                :post_recall_release_date,
                :release_date,
                :sentence_start_date,
                :tariff_date

    def initialize(fields = {})
      fields.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def automatic_release_date
      @automatic_release_override_date.presence || @automatic_release_date
    end

    def conditional_release_date
      @conditional_release_override_date.presence || @conditional_release_date
    end

    def post_recall_release_date
      post_recall_release_date = nomis_post_recall_release_date

      return post_recall_release_date if @actual_parole_date.blank?

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

    def self.from_json(payload)
      SentenceDetail.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    # rubocop:disable Metrics/MethodLength
    def load_from_json(payload)
      @parole_eligibility_date = deserialise_date(payload, 'paroleEligibilityDate')
      @release_date = deserialise_date(payload, 'releaseDate')
      @sentence_start_date = deserialise_date(payload, 'sentenceStartDate')
      @tariff_date = deserialise_date(payload, 'tariffDate')
      @automatic_release_date = deserialise_date(payload, 'automaticReleaseDate')
      @post_recall_release_date = deserialise_date(payload, 'postRecallReleaseDate')
      @post_recall_release_override_date = deserialise_date(payload, 'postRecallReleaseOverrideDate')
      @conditional_release_date = deserialise_date(
        payload, 'conditionalReleaseDate'
      )
      @automatic_release_override_date = deserialise_date(
        payload, 'automaticReleaseOverrideDate'
      )
      @home_detention_curfew_eligibility_date = deserialise_date(
        payload, 'homeDetentionCurfewEligibilityDate'
      )
      @home_detention_curfew_actual_date = deserialise_date(
        payload, 'homeDetentionCurfewActualDate'
      )
      @conditional_release_override_date = deserialise_date(
        payload, 'conditionalReleaseOverrideDate'
      )
      @actual_parole_date = deserialise_date(payload, 'actualParoleDate')
    end
  end
end
