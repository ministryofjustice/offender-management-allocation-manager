class AddParoleReviewDateToCaseInformation < ActiveRecord::Migration[5.2]
  def change
    change_table :case_information do |t|
      t.date :parole_review_date, null: true
    end
  end
end
