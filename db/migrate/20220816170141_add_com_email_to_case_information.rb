class AddComEmailToCaseInformation < ActiveRecord::Migration[6.1]
  def change
    add_column :case_information, :com_email, :varchar
  end
end
