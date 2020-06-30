class AddProbationServiceToCaseInformation < ActiveRecord::Migration[6.0]
  def change
    add_column :case_information, :probation_service, :string
  end
end
