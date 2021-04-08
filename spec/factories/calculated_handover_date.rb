# frozen_string_literal: true

FactoryBot.define do
  factory :calculated_handover_date do
    association :case_information

    start_date { Faker::Date.forward }

    handover_date { Faker::Date.forward }

    reason {
      # Randomly select a valid reason
      [:nps_indeterminate,
       :nps_mappa_unknown,
       :crc_case].sample
    }
  end
end
