# frozen_string_literal: true

class EmailHistory < ApplicationRecord
  EVENTS = [
    AUTO_EARLY_ALLOCATION = 'auto_early_allocation',
    DISCRETIONARY_EARLY_ALLOCATION = 'discretionary_early_allocation',
    SUITABLE_FOR_EARLY_ALLOCATION = 'suitable_for_early_allocation',
    OPEN_PRISON_COMMUNITY_ALLOCATION = 'open_prison_community_allocation',
    IMMEDIATE_COMMUNITY_ALLOCATION = 'immediate_community_allocation',
    RESPONSIBILITY_OVERRIDE = 'responsibility_override',
    URGENT_PIPELINE_TO_COMMUNITY = 'urgent_pipeline_to_community',
    COMMUNITY_EARLY_ALLOCATION = 'community_early_allocation'
  ].freeze

  belongs_to :offender,
             primary_key: :nomis_offender_id,
             foreign_key: :nomis_offender_id,
             inverse_of: :email_histories

  # name is the name of the person/LDU being emailed
  validates :name, presence: true

  validates :event, inclusion: { in: EVENTS, allow_nil: false }
  validates :prison, inclusion: { in: PrisonService.prison_codes, allow_nil: false }
  validates :email, presence: true, 'valid_email_2/email': true

  EVENTS.each { |event| scope event, -> { where(event:) } }

  def self.sent_within_current_sentence(offender, event)
    where(nomis_offender_id: offender.offender_no, event: event).where('created_at >= ?', offender.sentence_start_date)
  end

  def to_partial_path
    "case_history/email/#{event}"
  end
end
