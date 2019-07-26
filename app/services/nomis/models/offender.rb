# frozen_string_literal: true

module Nomis
  module Models
    class Offender < OffenderBase
      include MemoryModel

      delegate :home_detention_curfew_eligibility_date,
               :conditional_release_date, :release_date,
               :parole_eligibility_date, :tariff_date,
               :automatic_release_date,
               to: :sentence

      attribute :gender, :string
      attribute :latest_booking_id, :integer
      attribute :main_offence, :string
      attribute :nationalities, :string
      attribute :noms_id, :string
      attribute :reception_date, :date

      def early_allocation?
        false
      end

      def nps_case?
        case_allocation == 'NPS'
      end

      def pom_responsibility
        ResponsibilityService.new.calculate_pom_responsibility(self)
      end
    end
  end
end
