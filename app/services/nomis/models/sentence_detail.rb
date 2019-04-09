# frozen_string_literal: true

module Nomis
  module Models
    class SentenceDetail
      include MemoryModel

      attribute :first_name, :string
      attribute :last_name, :string
      attribute :home_detention_curfew_eligibility_date, :date
      attribute :parole_eligibility_date, :date
      attribute :release_date, :date
      attribute :sentence_start_date, :date
      attribute :tariff_date, :date

      def earliest_release_date
        dates = [
            release_date,
            parole_eligibility_date,
            home_detention_curfew_eligibility_date,
            tariff_date
        ].compact
        return nil if dates.empty?

        dates.min.to_date
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
