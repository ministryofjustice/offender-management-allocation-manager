FactoryBot.define do
  factory :omic_eligibility do
    nomis_offender_id { generate :nomis_offender_id }
    eligible { false }
    prison { 'LEI' }
    missing_runs_count { 0 }
  end
end
