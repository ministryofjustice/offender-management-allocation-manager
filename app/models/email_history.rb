# frozen_string_literal: true

class EmailHistory < ApplicationRecord
  AUTO_EARLY_ALLOCATION = 'auto_early_allocation'
  DISCRETIONARY_EARLY_ALLOCATION = 'discretionary_early_allocation'
  SUITABLE_FOR_EARLY_ALLOCATION = 'suitable_for_early_allocation'

  validates_presence_of :name, :nomis_offender_id

  validates :event, inclusion: { in: [AUTO_EARLY_ALLOCATION,
                                      DISCRETIONARY_EARLY_ALLOCATION,
                                      SUITABLE_FOR_EARLY_ALLOCATION], allow_nil: false }
  validates :prison, inclusion: { in: PrisonService.prison_codes, allow_nil: false }
  validates :email, presence: true, 'valid_email_2/email': true
end
