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

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:nomis_offender_id) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      "T#{number}T#{letter}"
    end

    association :team, code: '1234', name: 'A nice team'

    crn do Faker::Alphanumeric.alpha(number: 10) end

    probation_service do
      'Wales'
    end
  end
end
