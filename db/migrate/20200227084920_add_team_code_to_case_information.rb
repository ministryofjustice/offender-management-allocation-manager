class AddTeamCodeToCaseInformation < ActiveRecord::Migration[6.0]
  def change
    add_column :case_information, :team_code, :string
  end
end
