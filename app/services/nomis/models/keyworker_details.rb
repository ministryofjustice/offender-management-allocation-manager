# frozen_string_literal: true

module Nomis
  module Models
    class KeyworkerDetails
      include MemoryModel

      attribute :staff_id, :integer
      attribute :first_name, :string
      attribute :last_name, :string
    end
  end
end
