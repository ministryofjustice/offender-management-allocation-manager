# frozen_string_literal: true

class Responsibility < ApplicationRecord
  include Auditable

  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

  after_commit :save_audit_event

  belongs_to :offender,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :responsibility

  PRISON = 'Prison'
  PROBATION = 'Probation'

  # transient attribute used in the email sent, not persisted to the DB
  attr_accessor :message

  validates :nomis_offender_id, presence: true, uniqueness: true
  validates :reason_text,
            presence: {
              message: 'Please provide reason when Other is selected'
            },
            if: -> { reason == :other_reason.to_s }

  validates :reason, presence: {
    message: 'Select a reason for overriding the responsibility'
  }

  validates :value, inclusion: { in: [PRISON, PROBATION] }

  LESS_THAN_10_MONTHS_TO_SERVE = 0
  COMMUNITY_TEAM_TO_WORK_WITH_OFFENDER = 1
  PRISONER_HAS_BEEN_RECALLED = 2
  OTHER_REASON = 3
  PRISONER_MOVED_TO_OPEN_PRISON = 4

  enum :reason, {
    less_than_10_months_to_serve: LESS_THAN_10_MONTHS_TO_SERVE,
    community_team_to_work_with_offender: COMMUNITY_TEAM_TO_WORK_WITH_OFFENDER,
    prisoner_has_been_recalled: PRISONER_HAS_BEEN_RECALLED,
    other_reason: OTHER_REASON,
    prisoner_moved_to_open_prison: PRISONER_MOVED_TO_OPEN_PRISON
  }

  class << self
    def human_reason(reason)
      return '' if reason.blank?

      I18n.t(reason, scope: 'activerecord.attributes.responsibility.reasons', default: '')
    end
  end

  def human_reason
    self.class.human_reason(reason)
  end

  def pom_responsible? = value == PRISON
  def pom_supporting? = value == PROBATION
  def com_responsible? = value == PROBATION
  def com_supporting? = value == PRISON

private

  def audit_event_tags
    %w[record responsibility override].freeze
  end

  def audit_excluded_keys
    %w[reason_text created_at updated_at].freeze
  end
end
