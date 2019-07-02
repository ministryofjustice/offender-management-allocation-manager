class AddEmailForPoms < ActiveRecord::Migration[5.2]
  def up
    add_column :pom_details, :email, :string
  end

  def down
    remove_column :pom_details, :email
  end
end
