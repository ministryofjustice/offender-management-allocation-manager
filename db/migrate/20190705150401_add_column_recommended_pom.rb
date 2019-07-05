class AddColumnRecommendedPom < ActiveRecord::Migration[5.2]
  def up
    add_column :allocation_versions, :recommended_pom_type, :string
  end

  def down
    remove_column :allocation_versions, :recommended_pom_type
  end
end
