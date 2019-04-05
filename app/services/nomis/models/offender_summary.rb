# frozen_string_literal: true

module Nomis
  module Models
    class OffenderSummary
      include MemoryModel

      attribute :convicted_status, :string
      attribute :date_of_birth, :date
      attribute :first_name, :string
      attribute :gender, :string
      attribute :imprisonment_status, :string
      attribute :last_name, :string
      attribute :latest_booking_id, :integer
      attribute :main_offence, :string
      attribute :nationalities, :string
      attribute :noms_id, :string
      attribute :offender_no, :string
      attribute :reception_date, :date

      # custom attributes
      attribute :allocated_pom_name, :string
      attribute :case_allocation, :string
      attribute :home_detention_curfew_eligibility_date, :date
      attribute :omicable, :boolean
      attribute :parole_eligibility_date, :date
      attribute :release_date, :date
      attribute :sentence_start_date, :date
      attribute :tariff_date, :date
      attribute :tier, :string

      def sentence_detail=(sentence_detail)
        self.release_date = sentence_detail.release_date
        self.sentence_start_date = sentence_detail.sentence_start_date
        self.parole_eligibility_date = sentence_detail.parole_eligibility_date
        self.tariff_date = sentence_detail.tariff_date
        self.home_detention_curfew_eligibility_date =
          sentence_detail.home_detention_curfew_eligibility_date
      end

      def earliest_release_date
        dates = [
          release_date,
          parole_eligibility_date,
          home_detention_curfew_eligibility_date,
          tariff_date
        ].compact
        return nil if dates.empty?

        dates.min
      end

      def case_owner
        @case_owner ||= ResponsibilityService.new.calculate_case_owner(self)
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end

      def full_name_ordered
        "#{first_name} #{last_name}".titleize
      end
    end
  end
end
