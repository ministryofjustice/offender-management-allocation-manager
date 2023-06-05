require 'faker'

FactoryBot.define do
  factory :case_information do
    association :offender

    tier { 'A' }

    manual_entry { true }

    association :local_delivery_unit

    crn { Faker::Alphanumeric.alpha(number: 10) }

    probation_service { 'Wales' }

    enhanced_handover { false }

    trait :welsh do
      probation_service { 'Wales' }
    end

    trait :english do
      probation_service { 'England' }
    end

    trait :with_com do
      com_name { "#{Faker::Name.last_name}, #{Faker::Name.first_name}" }
    end

    trait :with_active_vlo do
      active_vlo { true }
    end
  end
end
