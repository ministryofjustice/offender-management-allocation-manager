FactoryBot.define do
  factory :hmpps_api_offender, class: 'HmppsApi::Offender' do
    initialize_with do
      HmppsApi::Offender.new(attributes.stringify_keys,
                             attributes.stringify_keys,
                             booking_id: attributes[:latestBookingId]&.to_i,
                             prison_id: attributes[:latestLocationId],
                             category: attributes.fetch(:category),
                             latest_temp_movement: nil,
                             complexity_level: attributes.fetch(:complexityLevel)).tap { |offender|
        offender.sentence = attributes.fetch(:sentence)
      }
    end

    latestLocationId { 'LEI' }

    trait :prescoed do
      latestLocationId { PrisonService::PRESCOED_CODE }
    end

    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    internalLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    offenderNo { generate :nomis_offender_id }
    sequence(:bookingId) { |x| x + 700_000 }
    convictedStatus { 'Convicted' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    category { build(:offender_category, :cat_c) }
    recall {  false }

    sentence { association :sentence_detail }

    complexityLevel { 'medium' }
  end
end
