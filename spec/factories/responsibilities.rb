FactoryBot.define do
  factory :responsibility do
    nomis_offender_id do "MyString" end
    reason do :less_than_10_months_to_serve end
    value { 'Probation' }
  end
end
