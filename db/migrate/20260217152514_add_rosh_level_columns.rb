class AddRoshLevelColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :allocation_history, :allocated_at_rosh, :string
    add_column :allocation_history_versions, :allocated_at_rosh, :string

    add_column :case_information, :rosh_level, :string
  end
end
