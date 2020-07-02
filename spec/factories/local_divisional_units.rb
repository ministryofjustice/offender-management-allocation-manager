FactoryBot.define do
  factory :local_divisional_unit do
    sequence(:code) { |seq| "LDU#{seq}" }
    name do 'An Uninteresting LDU' end
    email_address { Faker::Internet.email }
  end
end
