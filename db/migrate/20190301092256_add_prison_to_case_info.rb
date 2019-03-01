class AddPrisonToCaseInfo < ActiveRecord::Migration[5.2]
  def up
    add_column :case_information, :prison, :text
  end

  def down
    remove_column :case_information, :prison
  end
end
