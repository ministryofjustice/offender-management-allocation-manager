class ParoleReview < ApplicationRecord
  belongs_to :offender, foreign_key: :nomis_offender_id, inverse_of: :parole_review

  ACTIVE_REVIEW_STATUS = [
    'Active',
    'Active - REREFERRED',
    'Active - Future',
    'Active - Referred'
  ].freeze

  def current_hearing_outcome
    no_hearing_outcome? ? 'No hearing outcome yet' : format_hearing_outcome
  end

  def previous_hearing_outcome
    no_hearing_outcome? ? 'No hearing outcome given' : format_hearing_outcome
  end

  # If the hearing outcome received from PPUD is either 'Not Applicable' or 'Not Specified', this is equivalent to no hearing
  # outcome having been received. There should always be a value in the hearing_outcome field, and not having a nil check allows
  # this method to be used to determine the date that the hearing outcome was given.
  def no_hearing_outcome?
    hearing_outcome == 'Not Applicable' || hearing_outcome == 'Not Specified'
  end

  def active?
    ACTIVE_REVIEW_STATUS.include? review_status
  end

private

  # While the parsing is gnarly, there is a wide set of criteria that needs to be met for the hearing outcome to be displayed.
  # For exmaple, 'No Parole Board Decision - ABC [*]' may be received, but should be displayed as 'No Parole Board decision – ABC'
  # The hyphen gsub is to change a small hyphen with a large hyphen. It may look the same in the IDE, but it looks different in-app.
  def format_hearing_outcome
    return if hearing_outcome.blank?

    hearing_outcome.delete_suffix(' [*]').tr('-', '–').split(' ').map { |word|
      /[A-Z]{2,}|Parole|Board/.match?(word) ? word : word.downcase
    }.join(' ').upcase_first
  end
end
