# frozen_string_literal: true

FactoryBot.define do
  factory :calculated_handover_date do
    association :offender

    start_date { Faker::Date.forward }

    handover_date { Faker::Date.forward }

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
  end
end
