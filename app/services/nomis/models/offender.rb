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
      attribute :release_date, :date
      attribute :sentence_date, :date
      attribute :tier, :string
      attribute :case_allocation, :string
      attribute :welsh_address, :boolean

      def current_responsibility
        @current_responsibility = ResponsibilityService.calculate_responsibility(self)
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
