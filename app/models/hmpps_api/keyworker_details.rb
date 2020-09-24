# frozen_string_literal: true

module HmppsApi
  class KeyworkerDetails
    include Deserialisable

    attr_accessor :staff_id, :first_name, :last_name

    def self.from_json(json)
      KeyworkerDetails.new.tap { |obj|
        obj.staff_id = json['staffId']&.to_i
        obj.first_name = json['firstName']
        obj.last_name = json['lastName']
      }
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end
  end
end
