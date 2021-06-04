# frozen_string_literal: true

class RemoveHandoverDateForeignKey < ActiveRecord::Migration[6.0]
  def change
    remove_foreign_key "calculated_handover_dates", "case_information", column: "nomis_offender_id", primary_key: "nomis_offender_id"
  end
end
