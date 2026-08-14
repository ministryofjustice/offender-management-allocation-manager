FactoryBot.define do
  factory :omic_eligibility do
    nomis_offender_id { generate :nomis_offender_id }
    eligible { false }
    prison { 'LEI' }
  end
end
