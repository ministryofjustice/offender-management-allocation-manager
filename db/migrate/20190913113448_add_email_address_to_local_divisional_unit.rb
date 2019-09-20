class AddEmailAddressToLocalDivisionalUnit < ActiveRecord::Migration[5.2]
  def up
    add_column :local_divisional_units, :email_address, :string
  end

  def down
    remove_column :local_divisional_units, :email_address
  end
end
