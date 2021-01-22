# frozen_string_literal: true

class EmailHistory < ApplicationRecord
  AUTO_EARLY_ALLOCATION = 'auto_early_allocation'
  DISCRETIONARY_EARLY_ALLOCATION = 'discretionary_early_allocation'
  SUITABLE_FOR_EARLY_ALLOCATION = 'suitable_for_early_allocation'
  OPEN_PRISON_COMMUNITY_ALLOCATION = 'open_prison_community_allocation'

  validates_presence_of :name, :nomis_offender_id

  validates :event, inclusion: { in: [AUTO_EARLY_ALLOCATION,
                                      DISCRETIONARY_EARLY_ALLOCATION,
                                      SUITABLE_FOR_EARLY_ALLOCATION,
                                      OPEN_PRISON_COMMUNITY_ALLOCATION], allow_nil: false }
  validates :prison, inclusion: { in: PrisonService.prison_codes, allow_nil: false }
  validates :email, presence: true, 'valid_email_2/email': true

  # offender could have been at this prison multiple times, so order by newest first
  scope :welsh_open_prescoed, lambda { |nomis_offender_id|
    where(nomis_offender_id: nomis_offender_id, event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION).order('created_at DESC')
  }

  def to_partial_path
    "email_#{event}"
  end
end
