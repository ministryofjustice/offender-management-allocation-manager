class CreateContactSubmission < ActiveRecord::Migration[5.2]
  def change
    create_table :contact_submissions do |t|
      t.text :body, null: false
      t.string :email_address
      t.string :referrer
      t.string :user_agent
      t.string :prison
      t.string :name
      t.string :role
    end
  end
end