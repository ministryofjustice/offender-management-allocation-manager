module Nomis
  module Models
    class Offender
      include MemoryModel

      attribute :offender_no, :string
      attribute :noms_id, :string
      attribute :title, :string
      attribute :first_name, :string
      attribute :middle_names, :string
      attribute :last_name, :string
      attribute :date_of_birth, :date
      attribute :gender, :string
      attribute :sex_code, :string
      attribute :nationalities, :string
      attribute :currently_in_prison, :string
      attribute :latest_booking_id, :integer
      attribute :latest_location_id, :string
      attribute :latest_location, :string
      attribute :internal_location, :string
      attribute :pnc_number, :string
      attribute :cro_number, :string
      attribute :ethnicity, :string
      attribute :birth_country, :string
      attribute :religion, :string
      attribute :convicted_status, :string
      attribute :imprisonment_status, :string
      attribute :reception_date, :date
      attribute :marital_status, :string
      attribute :main_offence, :string
      attribute :tier, :string
      attribute :case_allocation, :string
      attribute :omicable, :boolean
      attribute :allocated_pom_name, :string
      attribute :release_date, :date
      attribute :sentence_start_date, :date
      attribute :parole_eligibility_date, :date
      attribute :home_detention_curfew_eligibility_date, :date
      attribute :tariff_date, :date

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
