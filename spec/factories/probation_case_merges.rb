FactoryBot.define do
  factory :probation_case_merge do
    sequence(:old_crn) { |n| "X#{n.to_s.rjust(5, '0')}A" }
    sequence(:new_crn) { |n| "X#{n.to_s.rjust(5, '0')}B" }
    active { true }
    superseded_at { nil }

    trait :inactive do
      active { false }
      superseded_at { Time.zone.now }
    end
  end
end
