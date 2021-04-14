require 'faker'

FactoryBot.define do
  factory :case_information do
    tier do
      'A'
    end

    case_allocation do
      CaseInformation::NPS
    end

    manual_entry do
      true
    end

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:nomis_offender_id) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and the offender should produce different values to avoid clashes
      "T#{number}C#{letter}"
    end

    association :team, code: '1234', name: 'A nice team'

    crn { Faker::Alphanumeric.alpha(number: 10) }

    probation_service { 'Wales' }

    trait :welsh do
      probation_service { 'Wales' }
    end

    trait :english do
      probation_service { 'England' }
    end

    trait :nps do
      case_allocation { CaseInformation::NPS }
    end

    trait :crc do
      case_allocation { CaseInformation::CRC }
    end

    trait :with_com do
      com_name { "#{Faker::Name.last_name}, #{Faker::Name.first_name}" }
    end

    trait :with_prd do
      parole_review_date {Time.zone.today + 8.months}
    end
  end
end
