# frozen_string_literal: true

module Nomis
  module Models
    class StaffDetails
      include MemoryModel

      attribute :staff_id
      attribute :first_name
      attribute :last_name
      attribute :status
      attribute :thumbnail_id
    end
  end
end
