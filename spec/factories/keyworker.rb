FactoryBot.define do
  factory :keyworker, class: Hash do
    initialize_with { attributes }

    sequence(:staffId) { |x| x + 1000  }
    firstName { Faker::Name.first_name }
    lastName { Faker::Name.last_name }
  end
end
