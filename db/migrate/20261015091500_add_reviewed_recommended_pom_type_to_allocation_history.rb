class AddReviewedRecommendedPomTypeToAllocationHistory < ActiveRecord::Migration[8.1]
  def change
    add_column :allocation_history, :reviewed_recommended_pom_type, :string
    add_column :allocation_history_versions, :reviewed_recommended_pom_type, :string
  end
end
