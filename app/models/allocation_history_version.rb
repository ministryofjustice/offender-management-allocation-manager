# frozen_string_literal: true

# NOTE: this is a YAML-exploded / flat table to store PaperTrail versions
# in a more easy to consume/query structure (columns) instead of YAML,
# mainly for DPR/reports purposes.
#
# DO NOT manipulate these records manually. This is intended to be an
# append-only intermediate table that simplifies PaperTrail records.
#
class AllocationHistoryVersion < ApplicationRecord
  belongs_to :allocation_history

  EXCLUDED_ATTRIBUTES = %w[
    id
    override_detail
    suitability_detail
    message
    primary_pom_name
    secondary_pom_name
    nomis_booking_id
    created_at
    updated_at
  ].freeze

  class << self
    # @param version [PaperTrail::Version] the PaperTrail version to create from
    # @return [AllocationHistoryVersion] the newly created record
    # @raise [ActiveRecord::RecordInvalid] if the record is invalid
    def create_from_papertrail!(version)
      create!(
        attrs_from_papertrail(version)
      )
    end

    # @param version [PaperTrail::Version] the PaperTrail version to extract attributes from
    # @return [Hash] a hash of attributes with excluded fields removed and metadata fields added
    def attrs_from_papertrail(version)
      attrs = PaperTrail.serializer.load(version.object)
      attrs.except(*EXCLUDED_ATTRIBUTES).merge(
        {
          allocation_history_id: version.item_id,
          created_by_username: version.whodunnit,
          created_at: version.created_at,
          allocation_created_at: attrs['created_at'],
          allocation_updated_at: attrs['updated_at'],
        }.stringify_keys
      )
    end
  end
end
