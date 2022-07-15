class UpdateParoleReviewDateToTargetHearingDate < ActiveRecord::Migration[6.1]
  def change
    rename_column :parole_records, :parole_review_date, :target_hearing_date
  end
end
