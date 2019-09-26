FactoryBot.define do
  factory :local_divisional_unit do
    code do 'BG12345' end
    name do 'Barnsley LDU' end
    email_address { 'joe.bloggs@example.com' }
  end
end
