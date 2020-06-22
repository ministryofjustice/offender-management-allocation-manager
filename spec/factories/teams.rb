FactoryBot.define do
  factory :team do
    sequence(:code) do |seq| "NA#{seq}" end
    sequence(:shadow_code) do |seq| "NS#{seq}" end
    sequence(:name) { |seq|
      "Team Number #{seq}"
    }

    trait :nps do
      sequence(:code) do |seq| "NA#{seq}" end
      sequence(:shadow_code) do |seq| "NS#{seq}" end
    end

    trait :crc do
      sequence(:code) do |seq| "CA#{seq}" end
      sequence(:shadow_code) do |seq| "CS#{seq}" end
    end

    association :local_divisional_unit, code: '123', name: "LDU Name", email_address: 'testldu@example.org'
  end
end
