class RemovePrisonFromCaseInfo < ActiveRecord::Migration[5.2]
  def up
    remove_column :case_information, :prison
  end

  def down
    add_column :case_information, :prison, :string
  end
end
