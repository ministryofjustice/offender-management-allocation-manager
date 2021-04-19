# frozen_string_literal: true

class FixupPomDetailsIndex < ActiveRecord::Migration[6.0]
  def change
    remove_index :pom_details, :nomis_staff_id
    add_index :pom_details, [:nomis_staff_id, :prison_code], unique: true
  end
end
