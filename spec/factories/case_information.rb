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
      'G12345'
    end
  end
end
