class ChangeColumnsForStaffId < ActiveRecord::Migration[5.2]
  def up
    rename_column :prison_offender_managers, :staff_id, :nomis_staff_id
  end

  def down
    rename_column :prison_offender_managers, :nomis_staff_id, :staff_id
  end
end
