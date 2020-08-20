require 'faker'

FactoryBot.define do
  factory :allocation do
    allocated_at_tier do
      'A'
    end

    created_by_username do
      'MOIC_POM'
    end

    created_by_name do
      "#{Faker::Name.first_name} #{Faker::Name.last_name}"
    end

    event do
      Allocation::ALLOCATE_PRIMARY_POM
    end

    event_trigger do
      Allocation::USER
    end

    nomis_booking_id do
      Faker::Number.number(digits: 7)
    end

    nomis_offender_id do
      Faker::Alphanumeric.alpha(number: 10)
    end

    primary_pom_nomis_id do
      485_926
      # using fake POM numbers tends to cause crashes
      # Faker::Number.number(digits: 7)
    end

    primary_pom_name do
      "#{Faker::Name.last_name}, #{Faker::Name.first_name}"
    end

    primary_pom_allocated_at do
      DateTime.now.utc
    end

    prison do
      'LEI'
    end

    updated_at do
      DateTime.now.utc
    end
  end
end
