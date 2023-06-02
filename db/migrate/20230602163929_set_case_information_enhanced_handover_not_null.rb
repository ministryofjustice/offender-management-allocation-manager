class SetCaseInformationEnhancedHandoverNotNull < ActiveRecord::Migration[6.1]
  def change
    execute("UPDATE case_information SET enhanced_handover = true WHERE case_allocation = 'NPS'")
    execute("UPDATE case_information SET enhanced_handover = false WHERE case_allocation = 'CRC'")
    change_column :case_information, :enhanced_handover, :boolean, null: false
  end
end
