# frozen_string_literal: true

class AddResponsibilityToCalculatedHandoverDates < ActiveRecord::Migration[6.0]
  def change
    change_table :calculated_handover_dates do |t|
      # This ought to be non-nullable, but we have existing data
      t.string :responsibility
    end
  end
end
