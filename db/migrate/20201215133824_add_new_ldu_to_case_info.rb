class AddNewLduToCaseInfo < ActiveRecord::Migration[6.0]
  def change
    change_table :case_information do |t|
      t.string :team_name
      t.references :local_delivery_unit
    end
  end
end
