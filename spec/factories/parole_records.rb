FactoryBot.define do
  factory :parole_record do
    association :offender

    parole_review_date {Time.zone.today + 8.months}
  end
end
