class AddDateOfBirthToDeliusData < ActiveRecord::Migration[5.2]
  def change
    change_table :delius_data do |t|
      t.string :date_of_birth
    end
  end
end
