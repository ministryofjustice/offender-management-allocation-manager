class ParoleReviewImport < ApplicationRecord
  RETENTION_PERIOD = 60.days

  scope :to_purge, lambda {
    where('processed_on IS NOT NULL AND processed_on < ?',
          Time.zone.today - RETENTION_PERIOD)
  }

  scope :to_process, lambda {
    where(processed_on: nil)
  }

  def sanitized_nomis_id
    nomis_id.tr('.', '') # They sometimes end with a period
  end

  def curr_target_date
    parse_date self[:curr_target_date]
  end

  def ms13_target_date
    parse_date self[:ms13_target_date]
  end

  def no_hearing_outcome?
    final_result == 'Not Applicable' || final_result == 'Not Specified'
  end

private

  # The dates are stored as different formats, depending on whether initial import or not
  def parse_date(str)
    return nil if str.blank? || str == 'NULL'

    Date.strptime(str, single_day_snapshot ? '%d-%m-%Y' : '%m/%d/%y')
  end
end