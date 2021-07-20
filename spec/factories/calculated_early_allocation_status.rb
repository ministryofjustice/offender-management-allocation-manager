# frozen_string_literal: true

FactoryBot.define do
  factory :calculated_early_allocation_status do
    association :offender
    eligible { false }
  end
end
