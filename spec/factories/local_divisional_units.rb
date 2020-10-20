FactoryBot.define do
  factory :local_divisional_unit do
    sequence(:code) { |seq| "LDU#{seq}" }
    sequence(:name) { |seq| "LDU Number #{seq}" }
    email_address { Faker::Internet.email }
  end
end
