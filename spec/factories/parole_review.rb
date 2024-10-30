FactoryBot.define do
  factory :parole_review do
    association :offender

    sequence(:review_id) { |x| x + 300_000 }

    # Defaults a parole review to be the currently active record
    review_status {'Active'}
    hearing_outcome {'Not Specified'} # = no hearing outcome

    trait :active do
      hearing_outcome { nil }
      review_status { 'Active' }
    end

    trait :completed do
      target_hearing_date { 1.year.from_now }
      hearing_outcome { 'Release [*]' }
    end

    trait :approaching_parole do
      target_hearing_date { Time.zone.today + 7.days } # Must be within the next 10 months
      hearing_outcome { 'Not Specified' } # = no hearing outcome
    end

    trait :pom_task do
      custody_report_due { Time.zone.today + 7.days } # Ensures it's sortable and thus can be most_recent_parole_review
      hearing_outcome { 'Return to Open' }
      hearing_outcome_received_on { nil } # The task is to fill this in
    end
  end
end
