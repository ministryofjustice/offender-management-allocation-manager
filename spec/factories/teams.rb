FactoryBot.define do
  factory :team do
    code do 'abcd' end
    shadow_code do 'ABCDEF' end
    name { 'The team' }
  end
end
