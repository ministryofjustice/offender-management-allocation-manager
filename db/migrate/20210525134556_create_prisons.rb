class CreatePrisons < ActiveRecord::Migration[6.0]
  def change
    create_table :prisons, id: false do |t|
      t.string :prison_type, null: false
      t.string :code, primary_key: true
      t.string :name, null: false, index: {unique: true}

      t.timestamps
    end
  end
end
