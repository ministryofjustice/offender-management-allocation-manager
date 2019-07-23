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
      Faker::Alphanumeric.alpha(10)
    end

    team do
      "A nice team"
    end

    ldu do "LDU Name" end
    crn { Faker::Alphanumeric.alpha(10) }
  end
end
