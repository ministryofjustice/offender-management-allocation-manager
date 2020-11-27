class AddEarlyAllocationReferralFields < ActiveRecord::Migration[6.0]
  def change
    change_table :early_allocations do |t|
      t.boolean :created_within_referral_window, null: false, default: false
      t.datetime :referred_to_ldu_at
      t.string :referred_to_ldu_name
      t.string :referred_to_ldu_email
    end
  end
end
