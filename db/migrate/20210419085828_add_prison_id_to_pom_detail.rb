# frozen_string_literal: true

class AddPrisonIdToPomDetail < ActiveRecord::Migration[6.0]
  def change
    change_table :pom_details do |t|
      t.string :prison_code, length: 3
    end
  end
end
