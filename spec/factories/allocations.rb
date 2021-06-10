FactoryBot.define do
  factory :allocation do
    association :offender
    association :pom_detail
    allocation_type { 'primary' }

    trait :primary do
      allocation_type { 'primary' }
    end

    trait :coworking do
      allocation_type { 'coworking' }
    end
  end
end
