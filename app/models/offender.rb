# frozen_string_literal: true

class Offender < ApplicationRecord
  has_paper_trail meta: { nomis_offender_id: :nomis_offender_id }

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

  delegate :handover_progress_complete?, to: :handover_progress_checklist, allow_nil: true

  delegate :handover_date, to: :calculated_handover_date, allow_nil: true

  def handover_progress_task_completion_data
    (handover_progress_checklist || build_handover_progress_checklist).task_completion_data
  end

  def handover_type
    if case_information.nil? || calculated_handover_date.nil?
      'missing'
    elsif case_information.enhanced_resourcing.nil?
      'enhanced'
    elsif calculated_handover_date.reason == 'determinate_short'
      'none'
    elsif case_information.enhanced_resourcing?
      'enhanced'
    else
      'standard'
    end
  end
end
