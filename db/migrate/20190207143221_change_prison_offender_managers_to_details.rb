class ChangePrisonOffenderManagersToDetails < ActiveRecord::Migration[5.2]
  def up
    rename_table :prison_offender_managers, :pom_details
    rename_column :allocations, :prison_offender_manager_id, :pom_detail_id
  end

  def down
    rename_table  :pom_details, :prison_offender_managers
    rename_column :allocations, :pom_detail_id, :prison_offender_manager_id
  end
end
