class ChangeStaffToPrisonOffenderManagers < ActiveRecord::Migration[5.2]
  def up
    rename_table :staff, :prison_offender_managers
  end

  def down
    rename_table :prison_offender_managers, :staff
  end
end
