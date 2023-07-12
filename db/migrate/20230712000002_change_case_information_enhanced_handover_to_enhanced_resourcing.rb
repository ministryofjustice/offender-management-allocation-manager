class ChangeCaseInformationEnhancedHandoverToEnhancedResourcing < ActiveRecord::Migration[6.1]
  def change
    rename_column :case_information, :enhanced_handover, :enhanced_resourcing
  end
end
