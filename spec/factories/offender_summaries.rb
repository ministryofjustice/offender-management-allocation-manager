FactoryBot.define do
  factory :offender_summary, class: 'HmppsApi::OffenderSummary' do
    inprisonment_status { 'SENT03' }
  end
end
