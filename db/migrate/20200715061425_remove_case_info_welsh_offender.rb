# frozen_string_literal: true

class RemoveCaseInfoWelshOffender < ActiveRecord::Migration[6.0]
  def change
    change_column_null :case_information, :probation_service, false
    remove_column :case_information, :welsh_offender
  end
end
