# frozen_string_literal: true

module HmppsApi
  class KeyworkerDetails
    attr_accessor :staff_id, :first_name, :last_name

    def self.from_json(json)
      KeyworkerDetails.new.tap do |obj|
        obj.staff_id = json['staffId']&.to_i
        obj.first_name = json['firstName']
        obj.last_name = json['lastName']
      end
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end
  end
end
