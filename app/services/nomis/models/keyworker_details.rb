# frozen_string_literal: true

module Nomis
  module Models
    class KeyworkerDetails
      include MemoryModel

      attribute :staff_id, :integer
      attribute :first_name, :string
      attribute :last_name, :string

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
