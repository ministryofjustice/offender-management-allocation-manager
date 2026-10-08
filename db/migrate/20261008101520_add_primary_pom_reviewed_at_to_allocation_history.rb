class AddPrimaryPomReviewedAtToAllocationHistory < ActiveRecord::Migration[8.1]
  def change
    add_column :allocation_history, :primary_pom_reviewed_at, :datetime
    add_column :allocation_history_versions, :primary_pom_reviewed_at, :datetime
  end
end
