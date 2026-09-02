class CreateNomisIdMerges < ActiveRecord::Migration[8.1]
  def change
    create_table :nomis_id_merges do |t|
      t.string :old_nomis_id, null: false
      t.string :new_nomis_id, null: false
      t.timestamps
    end

    add_index :nomis_id_merges, :old_nomis_id, unique: true
    add_index :nomis_id_merges, :new_nomis_id
  end
end
