# frozen_string_literal: true

class CaseInformation < ApplicationRecord
  self.table_name = 'case_information'

  MAPPA_LEVELS = [0, 1, 2, 3].freeze
  TIER_LEVELS = %w[A B C D].freeze
  ROSH_LEVELS = %w[VERY_HIGH HIGH MEDIUM LOW].freeze

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :case_information

  belongs_to :local_delivery_unit, -> { enabled }, optional: true, inverse_of: :case_information
  delegate :name, :email_address, to: :local_delivery_unit, prefix: :ldu, allow_nil: true

  validates :manual_entry, inclusion: { in: [true, false] }
  validates :nomis_offender_id, presence: true, uniqueness: true

  validates :tier, inclusion: { in: TIER_LEVELS, message: 'Select tier' }

  validates :rosh_level, inclusion: { in: ROSH_LEVELS, allow_blank: true }
  validates :rosh_level, presence: { message: 'Select ROSH' }, on: :manual_entry, if: :rosh_level_feature_enabled?

  validates :enhanced_resourcing,
            inclusion: { in: [true, false], message: 'Select case allocation decision' },
            on: :manual_entry

  # nil means MAPPA level is completely unknown.
  # 0 means MAPPA level is known to be not relevant for offender
  validates :mappa_level, inclusion: { in: MAPPA_LEVELS, allow_nil: true }

  scope :without_com, -> { where(com_name: nil) }

  def complete_for_allocation?
    tier.present? && (!rosh_level_feature_enabled? || rosh_level.present?)
  end

  def welsh_offender
    probation_service == 'Wales'
  end

private

  def rosh_level_feature_enabled?
    FeatureFlags.rosh_level.enabled?
  end
end
