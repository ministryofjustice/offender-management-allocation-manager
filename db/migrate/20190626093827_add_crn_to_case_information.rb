class AddCrnToCaseInformation < ActiveRecord::Migration[5.2]
  def up
    add_column :case_information, :crn, :string
  end

  def down
    remove_column :case_information, :crn
  end
end
