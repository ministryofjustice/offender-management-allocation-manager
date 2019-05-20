require 'faker'

FactoryBot.define do
  factory :allocation_version do
    allocated_at_tier do
      'A'
    end

    created_by_username do
      'SPO_LEEDS'
    end

    created_by_name do
      Faker::Name.name
    end

    event do
      AllocationVersion::ALLOCATE_PRIMARY_POM
    end

    event_trigger do
      AllocationVersion::USER
    end

    nomis_booking_id do
      Faker::Number.number(7)
    end

    nomis_offender_id do
      Faker::Alphanumeric.alpha(10)
    end

    primary_pom_nomis_id do
      Faker::Number.number(7)
    end

    primary_pom_name do
      Faker::Name.name
    end

    primary_pom_allocated_at do
      DateTime.now.utc
    end

    prison do
      'LEI'
    end
  end
end
