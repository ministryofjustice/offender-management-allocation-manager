class ParoleReviewImport < ApplicationRecord
  RETENTION_PERIOD = 60.days

  scope :to_purge, lambda {
    where('processed_on IS NOT NULL AND processed_on < ?',
          Time.zone.today - RETENTION_PERIOD)
  }

  scope :to_process, lambda {
    where(processed_on: nil).order(:snapshot_date, :row_number)
  }
end
