class UpdateColumnsInPoMs < ActiveRecord::Migration[5.2]
  def up
    change_column :prison_offender_managers, :nomis_staff_id, :integer, using: 'nomis_staff_id::integer', unique: true
    change_column :prison_offender_managers, :working_pattern, :float, using: 'working_pattern::float'
  end

  def down
    change_column :prison_offender_managers, :working_pattern, :string
    change_column :prison_offender_managers, :nomis_staff_id, :string
  end
end
