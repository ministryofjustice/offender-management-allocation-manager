FactoryBot.define do
  factory :team do
    sequence(:code) do |seq| "N#{seq}" end
    sequence(:shadow_code) do |seq| "SHAD#{seq}" end
    name do 'The team' end

    association :local_divisional_unit, code: '123', name: "LDU Name", email_address: 'testldu@example.org'
  end
end
