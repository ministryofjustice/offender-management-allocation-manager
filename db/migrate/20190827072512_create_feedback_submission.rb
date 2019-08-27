class CreateFeedbackSubmission < ActiveRecord::Migration[5.2]
  def change
    create_table :feedback_submissions do |t|
      t.text :body, null: false
      t.string :email_address
      t.string :referrer
      t.string :user_agent
      t.string :prison_id
    end
  end
end
