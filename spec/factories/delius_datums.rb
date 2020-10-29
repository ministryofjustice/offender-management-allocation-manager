FactoryBot.define do
  factory :delius_data do
    tier do
      'A'
    end
    provider_code do
      'NPS'
    end
    noms_no do
      'G4281GV'
    end
    crn do
      Faker::Number.number(digits: 8)
    end
    offender_manager { 'Smith, Bob' }
    # This has to match the T3 record for G4281GV above
    date_of_birth do '11/11/1964' end

    # By default delius data is welsh_offender
    ldu_code do 'WPT001' end
    ldu do 'Somewhere in Wales' end
    team_code do 'abcdefg' end
    team do 'A Welsh Team' end

    trait :with_mappa do
      mappa { 'Y' }
    end

    mappa  do 'N' end
    mappa_levels do nil end
  end
end
