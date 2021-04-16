class CreatePrisoners < ActiveRecord::Migration[6.0]
  def change
    create_table :prisoners do |t|
      t.timestamps
    end

    change_table :case_information do |t|
      t.references :prisoner
    end
  end
end
