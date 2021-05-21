class AddLduCodeToCaseInformation < ActiveRecord::Migration[6.0]
  def change
    add_column :case_information, :ldu_code, :string
  end
end
