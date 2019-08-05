class AddCaseInfoManualEntryFlag < ActiveRecord::Migration[5.2]
  def change
    change_table :case_information do |t|
      t.boolean :manual_entry, null: false, default: true
    end
    change_column_default :case_information, :manual_entry, nil
  end
end
