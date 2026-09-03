# frozen_string_literal: true

# Tracks probation CRN merges: when two probation case records are consolidated,
# the old (defunct) CRN points here to the successor. The chain may be followed
# to find the current canonical CRN (e.g. X1 -> X2 -> X3 means canonical(X1) = X3).
#
# Rows are lifecycle-aware: active rows represent current merge state, and rows
# are superseded (inactive) when an unmerge is processed.
#
class ProbationCaseMerge < ApplicationRecord
  include Auditable

  after_commit :save_audit_event

  scope :active, -> { where(active: true) }

  validates :old_crn, presence: true, uniqueness: { conditions: -> { where(active: true) } }, if: :active?
  validates :new_crn, presence: true
  validates :active, inclusion: { in: [true, false] }
  validate :does_not_create_cycle

  # Returns the current canonical CRN by following the merge chain.
  # If the CRN has never been merged, returns it unchanged.
  #
  #   ProbationCaseMerge.canonical_crn_for('X12345')
  #   # => 'X99999' (if X12345 -> X54321 -> X99999)
  #
  def self.canonical_crn_for(crn)
    seen = Set.new([crn])
    current = crn

    loop do
      merge = active.find_by(old_crn: current)
      return current unless merge

      next_crn = merge.new_crn
      # Cycle guard (should never happen with real probation data)
      return current if seen.include?(next_crn)

      seen << next_crn
      current = next_crn
    end
  end

  def self.record_merge!(old_crn:, new_crn:)
    current_active_merge = active.find_by(old_crn:)
    return current_active_merge if current_active_merge&.new_crn == new_crn

    if current_active_merge
      current_active_merge.update!(active: false, superseded_at: Time.current)
    end

    create!(old_crn:, new_crn:, active: true)
  end

  def self.record_unmerge!(old_crn:, new_crn:)
    merge = active.find_by(old_crn:, new_crn:)
    return false unless merge

    merge.update!(active: false, superseded_at: Time.current)
    true
  end

private

  def does_not_create_cycle
    return unless active?
    return if old_crn.blank? || new_crn.blank?
    return unless self.class.canonical_crn_for(new_crn) == old_crn

    errors.add(:new_crn, 'would create a merge cycle')
  end

  def audit_event_tags
    %w[record probation_case_merge].freeze
  end

  def audit_additional_data
    { 'canonical_crn' => self.class.canonical_crn_for(new_crn) }
  end
end
