class AddNewTeamIdToCaseInformation < ActiveRecord::Migration[6.0]
  def change
    add_column :case_information, :new_team_id, :integer
  end
end
