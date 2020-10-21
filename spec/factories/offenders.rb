# frozen_string_literal: true

FactoryBot.define do
  factory :offender_base, class: 'HmppsApi::Offender' do
    imprisonmentStatus { 'SENT03' }
    prisonId { 'LEI' }

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:offenderNo) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and case_information should produce different values to avoid clashes
      "T#{number}O#{letter}"
    end
    sequence(:bookingId) { |x| x + 700_000 }
    convictedStatus { 'Convicted' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    categoryCode { 'C' }
    recall {  false }

    sentence { association :sentence_detail }

    trait :determinate do
      imprisonmentStatus {'SEC90'}
    end
    trait :indeterminate do
      imprisonmentStatus {'LIFE'}
    end
    trait :indeterminate_recall do
      imprisonmentStatus {'LR_LIFE'}
      recall { true }
    end
    trait :determinate_recall do
      imprisonmentStatus {'LR_EPP'}
      recall { true }
    end
  end

  factory :offender, parent: :offender_base, class: 'HmppsApi::Offender' do
    initialize_with { HmppsApi::Offender.from_json(attributes.stringify_keys).tap { |offender| offender.sentence = attributes.fetch(:sentence)} }

    trait :prescoed do
      latestLocationId { PrisonService::PRESCOED_CODE }
    end
  end

  factory :nomis_offender, class: Hash do
    initialize_with { attributes }

    imprisonmentStatus { 'SENT03' }
    agencyId { 'LEI' }

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:offenderNo) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and case_information should produce different values to avoid clashes
      "T#{number}O#{letter}"
    end
    convictedStatus { 'Convicted' }
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    categoryCode { 'C' }
    recall { false }

    sentence do
      attributes_for :sentence_detail
    end

    sequence(:bookingId) { |c| c + 100_000 }
  end

  factory :nomis_prisoner, class: Hash do
    initialize_with { attributes }

    prisonId { 'LEI' }

    # offender numbers are of the form <letter><4 numbers><2 letters>
    sequence(:prisonerNumber) do |seq|
      number = seq / 26 + 1000
      letter = ('A'..'Z').to_a[seq % 26]
      # This and case_information should produce different values to avoid clashes
      "T#{number}O#{letter}"
    end
    dateOfBirth { Date.new(1990, 12, 6).to_s }
    firstName { Faker::Name.first_name }
    # We have some issues with corrupting the display
    # of names containing Mc or Du :-(
    # also ensure uniqueness as duplicate last names can cause issues
    # in tests, as ruby sort isn't stable by default
    sequence(:lastName) { |c| "#{Faker::Name.last_name.titleize}_#{c}" }
    category { 'C' }
    recall { false }
    indeterminateSentence { false }

    sentence do
      attributes_for :sentence_detail
    end

    sequence(:bookingId) { |c| c + 100_000 }
  end
end
