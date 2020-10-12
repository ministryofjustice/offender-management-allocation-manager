# frozen_string_literal: true

class Responsibility < ApplicationRecord
  belongs_to :case_information,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :responsibility

  PRISON = 'Prison'
  PROBATION = 'Probation'

  validates :nomis_offender_id, presence: true
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

  enum reason: {
    less_than_10_months_to_serve: LESS_THAN_10_MONTHS_TO_SERVE,
    community_team_to_work_with_offender: COMMUNITY_TEAM_TO_WORK_WITH_OFFENDER,
    prisoner_has_been_recalled: PRISONER_HAS_BEEN_RECALLED,
    other_reason: OTHER_REASON,
    prisoner_moved_to_open_prison: PRISONER_MOVED_TO_OPEN_PRISON
  }
end
