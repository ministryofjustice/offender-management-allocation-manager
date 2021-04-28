require 'faker'

FactoryBot.define do
  factory :case_information do
    association :offender

    tier do
      'A'
    end

    case_allocation do
      CaseInformation::NPS
    end

    manual_entry do
      true
    end

    association :local_delivery_unit

    crn { Faker::Alphanumeric.alpha(number: 10) }

    probation_service { 'Wales' }

    trait :welsh do
      probation_service { 'Wales' }
    end

    trait :english do
      probation_service { 'England' }
    end

    trait :nps do
      case_allocation { CaseInformation::NPS }
    end

    trait :crc do
      case_allocation { CaseInformation::CRC }
    end

    trait :with_com do
      com_name { "#{Faker::Name.last_name}, #{Faker::Name.first_name}" }
    end

    trait :with_prd do
      parole_review_date {Time.zone.today + 8.months}
    end
  end
end
