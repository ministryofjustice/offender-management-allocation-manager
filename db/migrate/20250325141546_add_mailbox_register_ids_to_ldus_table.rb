class AddMailboxRegisterIdsToLdusTable < ActiveRecord::Migration[7.1]
  def change
    add_column :local_delivery_units, :mailbox_register_id, :uuid
  end
end
