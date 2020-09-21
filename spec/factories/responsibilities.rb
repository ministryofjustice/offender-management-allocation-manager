FactoryBot.define do
  factory :responsibility do
    # mandatory field can't be defaulted sensibly
    # nomis_offender_id { "MyString" }
    reason { :less_than_10_months_to_serve }
    value { 'Probation' }
  end

  factory :remove_responsibility_form do
  end
end
