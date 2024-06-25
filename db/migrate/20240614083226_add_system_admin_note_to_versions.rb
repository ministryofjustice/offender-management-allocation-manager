class AddSystemAdminNoteToVersions < ActiveRecord::Migration[6.1]
  def change
    add_column :versions, :system_admin_note, :string
  end
end
