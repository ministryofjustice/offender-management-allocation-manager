# frozen_string_literal: true

module Nomis
  module Models
    class KeyworkerDetails
      include MemoryModel

      attribute :staff_id, :integer
      attribute :first_name, :string
      attribute :last_name, :string

      def full_name
        return "#{last_name}, #{first_name}".titleize if first_name || last_name

        'Not assigned'
      end
    end
  end
end
