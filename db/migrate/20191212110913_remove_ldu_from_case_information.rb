class RemoveLduFromCaseInformation < ActiveRecord::Migration[6.0]
  def up
    remove_column :case_information, :local_divisional_unit_id
  end

  def down
    change_table :case_information do |t|
      t.references :local_divisional_unit
    end
  end
end
