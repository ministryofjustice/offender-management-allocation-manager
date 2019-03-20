class ChangeWelshnessName < ActiveRecord::Migration[5.2]
  def up
    rename_column :case_information, :welsh_address, :omicable
  end

  def down
    rename_column :case_information, :omicable, :welsh_address
  end
end
