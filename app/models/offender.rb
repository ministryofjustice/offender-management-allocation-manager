# frozen_string_literal: true

class Offender < ApplicationRecord
  # NOMIS offender IDs must be of the form <letter><4 numbers><2 letters> (all uppercase)
  validates :nomis_offender_id, format: { with: /\A[A-Z][0-9]{4}[A-Z]{2}\z/ }

  has_one :case_information, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :early_allocations,
           -> { order(created_at: :asc) },
           foreign_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_many :email_histories,
           foreign_key: :nomis_offender_id,
           inverse_of: :offender,
           dependent: :destroy

  has_one :responsibility,
          foreign_key: :nomis_offender_id,
          inverse_of: :offender,
          dependent: :destroy

  has_one :calculated_handover_date,
          foreign_key: :nomis_offender_id,
          inverse_of: :offender,
          dependent: :destroy

  has_one :parole_record, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_one :calculated_early_allocation_status, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_many :victim_liaison_officers, foreign_key: :nomis_offender_id, inverse_of: :offender, dependent: :destroy

  has_one :handover_progress_checklist, foreign_key: :nomis_offender_id

  delegate :case_allocation, to: :case_information, allow_nil: true
end
