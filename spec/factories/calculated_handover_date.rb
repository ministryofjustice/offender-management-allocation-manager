# frozen_string_literal: true

FactoryBot.define do
  factory :calculated_handover_date do
    association :offender

    start_date { handover_date }

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

    trait :before_handover do
      responsibility { CalculatedHandoverDate::CUSTODY_ONLY }
      start_date { Faker::Date.forward }
      handover_date { Faker::Date.forward }
    end

    trait :after_handover do
      start_date { Faker::Date.backward }
      handover_date { Faker::Date.backward }
      responsibility { CalculatedHandoverDate::COMMUNITY_RESPONSIBLE }
    end
  end
end
