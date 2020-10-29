# frozen_string_literal: true

class MoveComNameToCaseInfo < ActiveRecord::Migration[6.0]
  def change
    change_table :case_information do |t|
      t.string :com_name
    end
  end
end