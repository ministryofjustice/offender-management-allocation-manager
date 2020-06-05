FactoryBot.define do
  factory :offender_summary, class: 'Nomis::OffenderSummary' do
    inprisonment_status { 'SENT03' }
  end
end
