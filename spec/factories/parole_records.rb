FactoryBot.define do
  factory :parole_record do
    association :offender

    # Defaults a parole record to be the currently active record
    review_status {'Active'}
    hearing_outcome {'Not Specified'}
    custody_report_due {Time.zone.today}
  end
end
