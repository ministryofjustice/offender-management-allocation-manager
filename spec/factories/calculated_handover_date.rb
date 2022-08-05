# frozen_string_literal: true

FactoryBot.define do
  factory :calculated_handover_date do
    association :offender

    com_allocated_date { Faker::Date.forward }

    com_responsible_date { Faker::Date.forward }

    reason {
      # Randomly select a valid reason
      CalculatedHandoverDate::REASONS.keys.sample
    }

    responsibility {
      # Randomly select a valid responsibility
      [
        CalculatedHandoverDate::CUSTODY_ONLY,
        CalculatedHandoverDate::CUSTODY_WITH_COM,
        CalculatedHandoverDate::COMMUNITY_RESPONSIBLE
      ].sample
    }

    trait :before_com_allocated_date do
      responsibility { CalculatedHandoverDate::CUSTODY_ONLY }
    end

    trait :between_com_allocated_and_responsible_dates do
      com_allocated_date { Faker::Date.backward }
      responsibility { CalculatedHandoverDate::CUSTODY_WITH_COM }
    end

    trait :after_com_responsible_date do
      com_allocated_date { Faker::Date.backward }
      com_responsible_date { Faker::Date.backward }
      responsibility { CalculatedHandoverDate::COMMUNITY_RESPONSIBLE }
    end
  end
end
