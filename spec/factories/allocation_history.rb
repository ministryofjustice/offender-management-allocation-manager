require 'faker'

FactoryBot.define do
  factory :allocation_history do
    allocated_at_tier do
      'A'
    end

    created_by_name do
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      "#{Faker::Name.first_name} #{Faker::Name.last_name.titleize}"
    end

    event do
      AllocationHistory::ALLOCATE_PRIMARY_POM
    end

    event_trigger do
      AllocationHistory::USER
    end

    nomis_offender_id

    primary_pom_nomis_id do
      485_926
      # using fake POM numbers tends to cause crashes
      # Faker::Number.number(digits: 7)
    end

    primary_pom_name do
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      "#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"
    end

    primary_pom_allocated_at do
      DateTime.now.utc
    end

    updated_at do
      DateTime.now.utc
    end

    trait :primary do
      event {AllocationHistory::ALLOCATE_PRIMARY_POM}
      event_trigger { AllocationHistory::USER }
      primary_pom_nomis_id { 123_456}
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      primary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :co_working do
      event {AllocationHistory::ALLOCATE_SECONDARY_POM}
      event_trigger { AllocationHistory::USER }
      primary_pom_nomis_id { 485_637 }
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      primary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
      secondary_pom_nomis_id { 485_926 }
      secondary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
    end

    trait :release do
      event { AllocationHistory::DEALLOCATE_RELEASED_OFFENDER }
      event_trigger {AllocationHistory::OFFENDER_RELEASED}
      primary_pom_nomis_id { nil}
      primary_pom_name { nil }
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :transfer do
      event { AllocationHistory::DEALLOCATE_PRIMARY_POM }
      event_trigger {AllocationHistory::OFFENDER_RELEASED}
      primary_pom_nomis_id { nil}
      primary_pom_name { nil }
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :reallocation do
      event {AllocationHistory::REALLOCATE_PRIMARY_POM}
      event_trigger { AllocationHistory::USER }
      primary_pom_nomis_id { 123_456}
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      primary_pom_name {"#{Faker::Name.last_name.titleize}, #{Faker::Name.first_name}"}
      secondary_pom_nomis_id { nil }
      secondary_pom_name { nil }
    end

    trait :override do
      override_detail {Faker::Lorem.sentence}
      suitability_detail {Faker::Lorem.sentence}
      override_reasons { ["suitability"] }
    end
  end
end
