class AddLduAndTeamToCaseInformation < ActiveRecord::Migration[5.2]
  def change
    change_table :case_information do |t|
      t.string :ldu
      t.string :team
    end
  end
end
