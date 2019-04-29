class AddSecondaryPomToAllocations < ActiveRecord::Migration[5.2]
  def up
    rename_column :allocations, :nomis_staff_id, :primary_pom_nomis_id
    rename_column :allocations, :pom_name, :primary_pom_name
    add_column :allocations, :secondary_pom_name, :text
    add_column :allocations, :secondary_pom_nomis_id, :int
    add_index :allocations, :secondary_pom_nomis_id
    remove_foreign_key :allocations, column: :pom_detail_id
    remove_column :allocations, :pom_detail_id
  end

  def down
    add_column :allocations, :pom_detail_id
    add_foreign_key :allocation, column: :pom_detail_id
    remove_index :allocations, :secondary_pom_nomis_id
    remove_column :allocations, :secondary_pom_nomis_id
    remove_column :allocations, :secondary_pom_name
    rename_column :allocations, :primary_pom_name, :pom_name
    rename_column :allocations, :primary_pom_nomis_id, :nomis_staff_id
  end
end
