class CreateParoleReviews < ActiveRecord::Migration[6.1]
  def change
    create_table :parole_reviews do |t|
      t.integer :review_id
      t.string :nomis_offender_id
      t.date :target_hearing_date
      t.date :custody_report_due
      t.string :review_status
      t.string :hearing_outcome
      t.date :hearing_outcome_received

      t.timestamps

      t.index [:review_id, :nomis_offender_id], unique: true, name: :index_parole_reviews_on_review_id_nomis_offender_id
    end
  end
end
