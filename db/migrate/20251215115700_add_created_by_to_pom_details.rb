class AddCreatedByToPomDetails < ActiveRecord::Migration[8.0]
  def change
    change_table :pom_details do |t|
      t.string :created_by
    end
  end
end
