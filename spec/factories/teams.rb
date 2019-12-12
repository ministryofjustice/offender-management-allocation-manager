FactoryBot.define do
  factory :team do
    code do 'abcd' end
    shadow_code do 'ABCDEF' end
    name do 'The team' end

    association :local_divisional_unit, code: '123', name: "LDU Name", email_address: 'testldu@example.org'
  end
end
