class DeliusCrnNotNullable < ActiveRecord::Migration[5.2]
  def up
    change_column_null :delius_data, :crn, false
  end

  def down
    change_column_null :delius_data, :crn, true
  end
end
