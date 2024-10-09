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

  def no_hearing_outcome?
    final_result == 'Not Applicable' || final_result == 'Not Specified'
  end
end
