FactoryBot.define do
  factory :hmpps_api_offender, class: 'HmppsApi::Offender' do
    initialize_with do
      # run attributes through JSON for a more realistic payload
      values_hash = JSON.parse(attributes.to_json)

      unless values_hash.member?(:prisonId)
        values_hash['prisonId'] = 'LEI'
      end

      # merge SentenceDetails into the main Offender object (Prison Search API returns it all in one)
      sentence = values_hash.extract!('sentence').fetch('sentence')
      values_hash.merge!(sentence)

      HmppsApi::Offender.new(offender: values_hash,
                             category: attributes.fetch(:category),
                             latest_temp_movement: nil,
                             complexity_level: attributes.fetch(:complexityLevel))
    end

    trait :prescoed do
      prisonId { PrisonService::PRESCOED_CODE }
    end

    # cell location is the format <1 letter>-<1 number>-<3 numbers> e.g 'E-4-014'
    cellLocation {
      block = Faker::Alphanumeric.alpha(number: 1).upcase
      num = Faker::Number.non_zero_digit
      numbers = Faker::Number.leading_zero_number(digits: 3)
      "#{block}-#{num}-#{numbers}"
    }

    prisonerNumber { generate :nomis_offender_id }
    sequence(:bookingId) { |x| x + 700_000 }
    legalStatus { 'SENTENCED' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    category { build(:offender_category, :cat_c) }
    recall {  false }

    sentence { attributes_for :sentence_detail }

    complexityLevel { 'medium' }
  end
end
