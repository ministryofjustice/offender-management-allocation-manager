class RemoveOldLduAndTeamData < ActiveRecord::Migration[6.0]
  def change
    remove_column :case_information, :team_id
    drop_table :local_divisional_units
    drop_table :teams
  end
end
