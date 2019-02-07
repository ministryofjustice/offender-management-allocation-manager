class ChangeAllocationNomisStaffIdDataType < ActiveRecord::Migration[5.2]
  def up
    change_column :allocations, :nomis_staff_id, :integer, using: 'nomis_staff_id::integer', unique: true
  end

  def down
    change_column :allocations, :nomis_staff_id, :string
  end
end
