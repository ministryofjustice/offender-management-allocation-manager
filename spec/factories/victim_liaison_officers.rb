FactoryBot.define do
  factory :victim_liaison_officer do
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    email { Faker::Internet.email }
    case_information { build(:case_information) }
  end
end
