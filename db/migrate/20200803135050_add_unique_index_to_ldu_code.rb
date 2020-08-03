class AddUniqueIndexToLduCode < ActiveRecord::Migration[6.0]
  def up
    remove_index :local_divisional_units, :code
    change_table :local_divisional_units do |t|
      t.index :code, unique: true
    end
  end

  def down
    remove_index :local_divisional_units, :code
    change_table :local_divisional_units do |t|
      t.index :code, unique: false
    end
  end
end
