class AddCaseInformationCountToTeams < ActiveRecord::Migration[6.0]
  def change
    add_column :teams, :case_information_count, :integer, null: false, default: 0

    reversible do |dir|
      dir.up { seed_counts }
    end
  end

  # Populate case_information_count for all teams
  def seed_counts
    execute <<-SQL.squish
        UPDATE teams
           SET case_information_count = (SELECT count(*)
                                           FROM case_information
                                          WHERE case_information.team_id = teams.id)
    SQL
  end
end
