module Nomis
  module Elite2
    class OffenderShort
      include MemoryModel

      attribute :booking_id, :integer
      attribute :booking_no, :string
      attribute :offender_no, :string
      attribute :first_name, :string
      attribute :middle_name, :string
      attribute :last_name, :string
      attribute :date_of_birth, :string
      attribute :age, :integer
      attribute :alerts_codes, :string
      attribute :alerts_details, :string
      attribute :agency_id, :string
      attribute :assigned_living_unit_id, :integer
      attribute :assigned_living_unit_desc, :string
      attribute :facial_image_id, :string
      attribute :assigned_officer_user_id, :string
      attribute :aliases, :string
      attribute :iep_level, :string
      attribute :category_code, :string
      attribute :rnum, :integer
      attribute :release_date, :date
      attribute :sentence_date, :date
      attribute :tier, :string
      attribute :allocated_pom_name, :string
      attribute :allocation_date, :date
      attribute :case_allocation, :string

      def awaiting_allocation_for
        return 0 if sentence_date.blank?

        (Time.zone.today - sentence_date).to_i
      end

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
