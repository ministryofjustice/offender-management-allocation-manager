class DropWelshOffenderFromCaseInformation < ActiveRecord::Migration[6.0]
  def change
    remove_column :case_information, :welsh_offender, :text
  end
end
