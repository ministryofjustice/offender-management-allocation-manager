# frozen_string_literal: true

class AddEarlyAllocationReferralFields < ActiveRecord::Migration[6.0]
  def change
    change_table :early_allocations do |t|
      t.boolean :created_within_referral_window, null: false, default: false
    end
    create_table :email_histories do |t|
      t.string :prison, null: false
      t.string :nomis_offender_id, null: false
      t.string :name, null: false
      t.string :email, null: false
      t.string :event, null: false
    end
  end
end
