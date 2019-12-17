FactoryBot.define do
  factory :local_divisional_unit do
    sequence(:code) do |seq| "LDU#{seq}" end
    name do 'An Uninteresting LDU' end
    email_address { Faker::Internet.email }
  end
end
