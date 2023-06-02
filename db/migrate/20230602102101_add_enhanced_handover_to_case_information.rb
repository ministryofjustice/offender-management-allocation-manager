class AddEnhancedHandoverToCaseInformation < ActiveRecord::Migration[6.1]
  def change
    add_column :case_information, :enhanced_handover, :boolean
  end
end
