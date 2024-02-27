FactoryBot.define do
  factory :parole_review do
    association :offender

    # Defaults a parole record to be the currently active record
    review_status {'Active'}
    hearing_outcome {'Not Specified'}
  end
end