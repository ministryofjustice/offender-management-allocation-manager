require 'faker'

FactoryBot.define do
  factory :case_information do
    tier do
      'A'
    end

    omicable do
      'Yes'
    end

    case_allocation do
      'NPS'
    end

    manual_entry do
      true
    end

    nomis_offender_id do
      Faker::Alphanumeric.alpha(number: 10)
    end

    association :team, code: '1234', name: 'A nice team'

    association :local_divisional_unit, code: '123', name: "LDU Name"

    crn { Faker::Alphanumeric.alpha(number: 10) }
  end
end
