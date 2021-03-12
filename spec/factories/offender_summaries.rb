# frozen_string_literal: true

FactoryBot.define do
  factory :offender_summary, class: 'HmppsApi::OffenderSummary', parent: :offender_base do
    initialize_with do
      HmppsApi::OffenderSummary.from_json(attributes.stringify_keys,
                                          recall_flag: attributes.fetch(:recall),
                                          latest_temp_movement: nil).tap { |offender|
        offender.sentence = attributes.fetch(:sentence)}
    end

    agencyId { 'LEI' }

    trait :prescoed do
      agencyId { PrisonService::PRESCOED_CODE }
    end
  end
end
