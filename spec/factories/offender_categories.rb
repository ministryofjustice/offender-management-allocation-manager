# frozen_string_literal: true

FactoryBot.define do
  factory :offender_category, class: HmppsApi::OffenderCategory do
    initialize_with { HmppsApi::OffenderCategory.new(attributes.reject { |_k, v| v.nil? }.stringify_keys) }

    classificationCode { 'A' }
    classification { 'Cat A' }
    approvalDate { 3.days.ago }

    trait :without_approval_date do
      approvalDate { nil }
      assessmentDate { 5.days.ago }
    end

    # Men's categories

    trait :cat_a do
      classificationCode { 'A' }
      classification { 'Cat A' }
    end

    trait :cat_b do
      classificationCode { 'B' }
      classification { 'Cat B' }
    end

    trait :cat_c do
      classificationCode { 'C' }
      classification { 'Cat C' }
    end

    trait :cat_d do
      classificationCode { 'D' }
      classification { 'Cat D' }
    end

    # Women's categories

    trait :female_restricted do
      classificationCode { 'Q' }
      classification { 'Female Restricted' }
    end

    trait :female_closed do
      classificationCode { 'R' }
      classification { 'Female Closed' }
    end

    trait :female_semi do
      classificationCode { 'S' }
      classification { 'Female Semi' }
    end

    trait :female_open do
      classificationCode { 'T' }
      classification { 'Female Open' }
    end
  end
end
