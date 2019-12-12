require 'faker'

FactoryBot.define do
  factory :case_information do
    tier do
      'A'
    end

    welsh_offender do
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

    crn { Faker::Alphanumeric.alpha(number: 10) }
  end
end
