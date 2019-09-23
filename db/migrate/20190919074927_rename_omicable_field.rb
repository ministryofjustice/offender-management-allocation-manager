class RenameOmicableField < ActiveRecord::Migration[5.2]
  def up
    rename_column :case_information, :omicable, :welsh_offender
  end

  def down
    rename_column :case_information, :welsh_offender, :omicable
  end
end
