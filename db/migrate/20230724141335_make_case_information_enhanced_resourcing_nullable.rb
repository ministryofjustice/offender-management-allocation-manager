class MakeCaseInformationEnhancedResourcingNullable < ActiveRecord::Migration[6.1]
  def change
    # Valid enhanced_resourcing values are true, false, and nil if no decision yet made
    change_column_null :case_information, :enhanced_resourcing, true
  end
end
