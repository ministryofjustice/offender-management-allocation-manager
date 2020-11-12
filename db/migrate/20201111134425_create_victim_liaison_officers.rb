class CreateVictimLiaisonOfficers < ActiveRecord::Migration[6.0]
  def change
    create_table :victim_liaison_officers do |t|
      t.references :case_information, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false

      t.timestamps
    end
  end
end
