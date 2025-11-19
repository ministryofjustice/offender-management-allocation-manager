require 'faker'

FactoryBot.define do
  factory :email_history do
    prison do
      'LEI'
    end

    nomis_offender_id

    name do
      # The last name is titleized after it's received from the API, e.g. "McDonald" becomes "Mcdonald"
      # So we also .titleize the last name here to avoid breaking tests
      "#{Faker::Name.first_name} #{Faker::Name.last_name.titleize}"
    end

    email do
      Faker::Internet.email
    end

    trait :immediate_community_allocation do
      event { EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION }
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

    trait :open_prison_community_allocation do
      event { EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION }
    end
  end
end
