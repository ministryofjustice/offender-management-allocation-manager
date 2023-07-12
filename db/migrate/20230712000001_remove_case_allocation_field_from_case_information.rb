class RemoveCaseAllocationFieldFromCaseInformation < ActiveRecord::Migration[6.1]
  def change
    remove_column :case_information, :case_allocation
  end
end
