class CreateLocalDivisionalUnits < ActiveRecord::Migration[5.2]
  def change
    create_table :local_divisional_units do |t|
      t.string :code
      t.string :name
      t.timestamps

      t.index :code
    end

    create_table :teams do |t|
      t.string :code
      t.string :name

      t.timestamps

      t.index :code
    end

    change_table :case_information do |t|
      t.references :local_divisional_unit
      t.references :team
    end
  end
end
