class AddWelshAddressFlag < ActiveRecord::Migration[5.2]
  def up
    add_column :case_information, :welsh_address, :text
  end

  def down
    remove_column :case_information, :welsh_address
  end
end
