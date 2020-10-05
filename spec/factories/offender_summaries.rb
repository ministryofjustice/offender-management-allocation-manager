# frozen_string_literal: true

FactoryBot.define do
  factory :offender_summary, class: 'HmppsApi::OffenderSummary', parent: :offender do
    initialize_with { HmppsApi::OffenderSummary.from_json(attributes.stringify_keys).tap { |offender| offender.sentence = attributes.fetch(:sentence)} }

    trait :prescoed do
      agencyId { PrisonService::PRESCOED_CODE }
    end
  end
end
