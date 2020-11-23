# frozen_string_literal: true

class AddNomisOffenderIdToPaperTrailVersion < ActiveRecord::Migration[6.0]
  def change
    change_table :versions do |t|
      t.string :nomis_offender_id
      t.index :nomis_offender_id
    end
  end
end
