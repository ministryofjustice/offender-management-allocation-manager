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
  end
end
