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
    
    trait :upcoming_handover do
      before_handover
    end

    trait :before_handover do
      responsibility { CalculatedHandoverDate::CUSTODY_ONLY }
      handover_date { rand(1.week.from_now..((DEFAULT_UPCOMING_HANDOVER_WINDOW_DURATION-1).days.from_now)) }
    end
    
    trait :handover_in_progress do
      after_handover
    end

    trait :after_handover do
      responsibility { CalculatedHandoverDate::COMMUNITY_RESPONSIBLE }
      handover_date { Faker::Date.backward }
    end
  end
end
