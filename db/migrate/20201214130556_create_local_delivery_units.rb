# frozen_string_literal: true

class CreateLocalDeliveryUnits < ActiveRecord::Migration[6.0]
  def change
    create_table :local_delivery_units do |t|
      t.string :code, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :email_address, null: false
      t.string :country, null: false
      t.boolean :enabled, null: false

      t.timestamps
    end
  end
end
