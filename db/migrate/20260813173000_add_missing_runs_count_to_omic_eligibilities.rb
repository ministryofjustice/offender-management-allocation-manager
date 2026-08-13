# frozen_string_literal: true

class AddMissingRunsCountToOmicEligibilities < ActiveRecord::Migration[8.1]
  def change
    add_column :omic_eligibilities, :missing_runs_count, :integer, default: 0, null: false
    add_index :omic_eligibilities, :missing_runs_count

    change_column_null :omic_eligibilities, :prison, false
  end
end
