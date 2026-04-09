class AddRoshStartDateColumn < ActiveRecord::Migration[8.1]
  def change
    add_column :case_information, :rosh_start_date, :date
  end
end
