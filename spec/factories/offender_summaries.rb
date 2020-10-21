# frozen_string_literal: true

FactoryBot.define do
  factory :offender_summary, class: 'HmppsApi::OffenderSummary', parent: :offender_base do
    initialize_with { HmppsApi::OffenderSummary.from_json(attributes.reject { |_k, v| v.nil? }.stringify_keys).tap { |offender| offender.sentence = attributes.fetch(:sentence)} }

    agencyId { 'LEI' }

    trait :prescoed do
      agencyId { PrisonService::PRESCOED_CODE }
    end
  end
end
