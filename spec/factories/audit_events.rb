FactoryBot.define do
  factory :audit_event do
    nomis_offender_id
    tags { %w[test occurrence] }
    published_at { Faker::Time.backward }
    system_event { true }
    data do
      {
        'noop' => true,
      }
    end

    trait :system

    trait :user do
      system_event { false }
      username { Faker::Internet.username }
      user_human_name { Faker::Name.name_with_middle }
    end
  end
end
