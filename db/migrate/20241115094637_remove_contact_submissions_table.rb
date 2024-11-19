class RemoveContactSubmissionsTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :contact_submissions
  end
end
