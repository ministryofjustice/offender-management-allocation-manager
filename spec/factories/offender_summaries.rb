# frozen_string_literal: true

FactoryBot.define do
  factory :offender_summary, class: 'HmppsApi::OffenderSummary', parent: :offender_base do
    initialize_with do
      HmppsApi::OffenderSummary.new(attributes.stringify_keys,
                                    attributes.stringify_keys,
                                    latest_temp_movement: nil,
                                    complexity_level: attributes.fetch(:complexityLevel)).tap { |offender|
        offender.sentence = attributes.fetch(:sentence)}
    end

    agencyId { 'LEI' }

    trait :prescoed do
      agencyId { PrisonService::PRESCOED_CODE }
    end
  end
end
