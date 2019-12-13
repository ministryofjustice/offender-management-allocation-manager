FactoryBot.define do
  factory :local_divisional_unit do
    sequence(:code) do |seq| "N#{seq}" end
    name do 'Barnsley LDU' end
    email_address { 'joe.bloggs@example.com' }
  end
end
