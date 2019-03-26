class AddSuitabilityDetailColumnToOverrides < ActiveRecord::Migration[5.2]
  def up
    add_column :overrides, :suitability_detail, :string
    add_column :allocations, :suitability_detail, :string
  end

  def down
    remove_column :overrides, :suitability_detail
    remove_column :allocations, :suitability_detail
  end
end
