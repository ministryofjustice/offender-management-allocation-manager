class ParoleReview < ApplicationRecord
  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :parole_reviews
  has_one :previous_review

  ACTIVE_REVIEW_STATUS = [
    'Active',
    'Active - REREFERRED',
    'Active - Future',
    'Active - Referred'
  ].freeze

  # If neither the THD or custody_report_due date are defined, we have no method
  # of determining when the parole hearing was, which is vital for MPC.
  scope :ordered_by_sortable_date, lambda {
    where(Arel.sql('COALESCE(target_hearing_date, custody_report_due) IS NOT NULL'))
    .order(Arel.sql('COALESCE(target_hearing_date, custody_report_due)'))
  }

  scope :with_hearing_outcome, -> { where.not(hearing_outcome: ['Not Applicable', 'Not Specified', nil]).or(where.not(hearing_outcome_received_on: nil)) }

  validate :hearing_outcome_received_on_must_be_in_past, on: :manual_update

  # Used when POM manually enters this date
  def hearing_outcome_received_on_must_be_in_past
    if hearing_outcome_received_on.blank?
      errors.add('hearing_outcome_received_on',
                 'The date the hearing outcome was confirmed must be entered and a valid date')
    elsif hearing_outcome_received_on.future?
      errors.add('hearing_outcome_received_on',
                 'The date the hearing outcome was confirmed must be in the past')
    end
  end

  def hearing_outcome_as_current
    no_hearing_outcome? ? 'No hearing outcome yet' : formatted_hearing_outcome
  end

  def hearing_outcome_as_historic
    no_hearing_outcome? ? 'Refused' : formatted_hearing_outcome
  end

  def formatted_hearing_outcome
    return nil if hearing_outcome.blank?

    hearing_outcome
      .delete_suffix(' [*]')
      .tr('-', '–')
      .split(' ')
      .map { |word| /[A-Z]{2,}|Parole|Board/.match?(word) ? word : word.downcase }
      .join(' ')
      .upcase_first
  end

  # If the hearing outcome received from PPUD is either 'Not Applicable' or 'Not Specified', this is equivalent to no hearing
  # outcome having been received. There should always be a value in the hearing_outcome field, and not having a nil check allows
  # this method to be used to determine the date that the hearing outcome was given.
  def no_hearing_outcome?
    hearing_outcome.blank? || hearing_outcome.in?(['Not Applicable', 'Not Specified'])
  end

  def outcome_is_release?
    hearing_outcome == 'Release [*]'
  end

  def outcome_is_not_release?
    hearing_outcome != 'Release [*]'
  end

  def active?
    ACTIVE_REVIEW_STATUS.include? review_status
  end
end
