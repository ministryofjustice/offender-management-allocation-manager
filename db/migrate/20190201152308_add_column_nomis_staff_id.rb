class AddColumnNomisStaffId < ActiveRecord::Migration[5.2]
  def up
    add_column :allocations, :nomis_staff_id, :string
  end

  def down
    remove_column :allocations, :nomis_staff_id
  end
end
