FactoryBot.define do
  factory :parole_record do
    association :offender

    target_hearing_date {Time.zone.today + 8.months}
  end
end
