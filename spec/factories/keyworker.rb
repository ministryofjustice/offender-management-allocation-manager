# frozen_string_literal: true

FactoryBot.define do
  factory :keyworker, class: HmppsApi::KeyworkerDetails do
    initialize_with { HmppsApi::KeyworkerDetails.from_json(attributes) }

    sequence(:staffId) { |x| x + 1000  }
    firstName { Faker::Name.first_name }
    lastName { Faker::Name.last_name }
  end
end
