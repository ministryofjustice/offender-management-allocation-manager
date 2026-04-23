require 'faker'

FactoryBot.define do
  factory :case_information do
    association :offender
    association :local_delivery_unit

    tier { 'A' }

    rosh_level { 'HIGH' }
    rosh_start_date { Date.new(2025, 6, 1) }

    manual_entry { false }

    crn { Faker::Alphanumeric.alpha(number: 10) }

    enhanced_resourcing { false }

    trait :welsh do
      probation_service { 'Wales' }
    end

    trait :english do
      probation_service { 'England' }
    end

    trait :manual_entry do
      manual_entry { true }
    end

    trait :with_com do
      com_name { "#{Faker::Name.last_name}, #{Faker::Name.first_name}" }
    end

    trait :with_active_vlo do
      active_vlo { true }
    end

    trait :without_rosh do
      rosh_level { nil }
      rosh_start_date { nil }
    end
  end
end
