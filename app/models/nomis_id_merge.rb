# frozen_string_literal: true

# Tracks NOMIS ID merges: when two prisoner records are consolidated in NOMIS,
# the old (defunct) ID points here to the successor. The chain may be followed
# to find the current canonical ID (e.g. A -> B -> C means canonical(A) = C).
# The table is insert-only and created_at records when the merge was processed.
#
class NomisIdMerge < ApplicationRecord
  include Auditable

  after_commit :save_audit_event

  validates :old_nomis_id, presence: true, uniqueness: true
  validates :new_nomis_id, presence: true

  # Returns the current canonical NOMIS ID by following the merge chain.
  # If the ID has never been merged, returns it unchanged.
  #
  #   NomisIdMerge.canonical_id_for('A1234BC')
  #   # => 'Q1111ZZ'  (if A1234BC -> Z9876XY -> Q1111ZZ)
  #
  def self.canonical_id_for(nomis_id)
    seen = Set.new([nomis_id])
    current = nomis_id

    loop do
      merge = find_by(old_nomis_id: current)
      return current unless merge

      next_id = merge.new_nomis_id
      # Cycle guard (should never happen with real NOMIS data)
      return current if seen.include?(next_id)

      seen << next_id
      current = next_id
    end
  end

  # So `Auditable` assigns this to the audit record, for easier filter/lookups later
  def nomis_offender_id
    old_nomis_id
  end

private

  def audit_event_tags
    %w[record nomis_id_merge].freeze
  end

  def audit_additional_data
    { 'canonical_id' => self.class.canonical_id_for(new_nomis_id) }
  end
end
