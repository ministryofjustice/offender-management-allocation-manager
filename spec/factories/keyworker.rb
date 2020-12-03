# frozen_string_literal: true

FactoryBot.define do
  factory :keyworker, class: HmppsApi::KeyworkerDetails do
    initialize_with { HmppsApi::KeyworkerDetails.from_json(attributes) }

    sequence(:staffId) { |x| x + 1000  }
    # Keyworker 'full name' is titleized as it's passed through KeyworkerDetails, e.g. "McDonald, Ronald" becomes "Mcdonald, Ronald"
    # So we also .titleize the first and last name here to avoid breaking tests
    firstName { Faker::Name.first_name.titleize }
    lastName { Faker::Name.last_name.titleize }
  end
end
