# frozen_string_literal: true

# NOTE: this is a YAML-exploded / flat table to store PaperTrail versions
# in a more easy to consume/query structure (columns) instead of YAML,
# mainly for DPR/reports purposes.
#
# DO NOT manipulate these records manually. This is intended to be an
# append-only intermediate table that simplifies PaperTrail records.
#
class AllocationHistoryVersion < ApplicationRecord
  belongs_to :allocation_history, optional: true

  ATTRS_FROM_PAPERTRAIL = %w[
    nomis_offender_id
    prison
    allocated_at_tier
    override_reasons
    created_by_name
    primary_pom_nomis_id
    secondary_pom_nomis_id
    event
    event_trigger
    primary_pom_allocated_at
    recommended_pom_type
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
    # @return [Hash] a hash of attributes ready for creating an AllocationHistoryVersion record
    def attrs_from_papertrail(version)
      attrs = PaperTrail.serializer.load(version.object)

      # NOTE: only for the bulk historical records import
      # Some very old records (~2019) have a nil `prison`, which triggers
      # the PG::NotNullViolation constraint on this new table. Rather than
      # skipping these rows, we set the `prison` attr to an empty string.
      attrs['prison'] ||= ''

      attrs.slice(*ATTRS_FROM_PAPERTRAIL).reverse_merge(
        {
          allocation_history_id: version.item_id,
          created_by_username: version.whodunnit,
          created_at: version.created_at,
          allocation_created_at: attrs['created_at'],
          allocation_updated_at: attrs['updated_at'],
          # below attributes might not exist in very old PT versions, so we set defaults
          primary_pom_allocated_at: nil,
          recommended_pom_type: nil,
        }.stringify_keys
      )
    end
  end
end
