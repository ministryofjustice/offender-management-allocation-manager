require 'faker'

FactoryBot.define do
  factory :email_history do
    prison do
      'LEI'
    end

    sequence(:nomis_offender_id) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and the offender should produce different values to avoid clashes
      "T#{number}C#{letter}"
    end

    name do
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      "#{Faker::Name.first_name} #{Faker::Name.last_name.titleize}"
    end

    email do
      Faker::Internet.email
    end

    trait :auto_early_allocation do
      event { EmailHistory::AUTO_EARLY_ALLOCATION }
    end

    trait :discretionary_early_allocation do
      event { EmailHistory::DISCRETIONARY_EARLY_ALLOCATION }
    end

    trait :suitable_early_allocation do
      event { EmailHistory::SUITABLE_FOR_EARLY_ALLOCATION }
    end
  end
end
