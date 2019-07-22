FactoryBot.define do
  factory :delius_data do
    trait :with_mappa do
      mappa { 'Y' }
    end

    mappa  do 'N' end
    mappa_levels do nil end

    tier do 'A' end
    provider_code do 'NPS' end
    noms_no { Faker::Alphanumeric.alpha(10) }
  end
end
