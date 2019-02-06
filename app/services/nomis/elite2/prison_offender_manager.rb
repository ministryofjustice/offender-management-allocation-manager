module Nomis
  module Elite2
    class PrisonOffenderManager
      include MemoryModel

      attribute :staff_id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :agency_id, :string
      attribute :agency_description, :string
      attribute :from_date, :date
      attribute :position, :string
      attribute :position_description, :string
      attribute :role, :string
      attribute :role_description, :string
      attribute :schedule_type, :string
      attribute :schedule_type_description, :string
      attribute :hours_per_week, :integer
      attribute :thumbnail_id, :string

      attribute :tier_a, :integer
      attribute :tier_b, :integer
      attribute :tier_c, :integer
      attribute :tier_d, :integer
      attribute :total_cases, :integer
      attribute :status, :string
      attribute :working_pattern, :string
      attribute :number_allocated, :string

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
