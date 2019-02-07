class RenameColumnOffenderNo < ActiveRecord::Migration[5.2]
  def up
    rename_column :allocations, :offender_no, :nomis_offender_id
  end

  def down
    rename_column :allocations, :nomis_offender_id, :offender_no
  end
end
