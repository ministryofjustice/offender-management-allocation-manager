# frozen_string_literal: true

class EmailHistory < ApplicationRecord
  AUTO_EARLY_ALLOCATION = 'auto_early_allocation'
  DISCRETIONARY_EARLY_ALLOCATION = 'discretionary_early_allocation'
  SUITABLE_FOR_EARLY_ALLOCATION = 'suitable_for_early_allocation'
  OPEN_PRISON_COMMUNITY_ALLOCATION = 'open_prison_community_allocation'
  IMMEDIATE_COMMUNITY_ALLOCATION = 'immediate_community_allocation'

  belongs_to :case_information,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :email_histories

  # name is the name of the person/LDU being emailed
  validates_presence_of :name

  validates :event, inclusion: { in: [AUTO_EARLY_ALLOCATION,
                                      DISCRETIONARY_EARLY_ALLOCATION,
                                      SUITABLE_FOR_EARLY_ALLOCATION,
                                      OPEN_PRISON_COMMUNITY_ALLOCATION,
                                      IMMEDIATE_COMMUNITY_ALLOCATION], allow_nil: false }
  validates :prison, inclusion: { in: PrisonService.prison_codes, allow_nil: false }
  validates :email, presence: true, 'valid_email_2/email': true

  # This scope removes history records which are not supposed to be displayed in the offender timeline (case history page)
  scope :in_offender_timeline, -> { where.not(event: IMMEDIATE_COMMUNITY_ALLOCATION) }

  def self.sent_within_current_sentence(offender, event)
    where(nomis_offender_id: offender.offender_no, event: event).where('created_at >= ?', offender.sentence_start_date)
  end

  def to_partial_path
    "case_history/email/#{event}"
  end
end
