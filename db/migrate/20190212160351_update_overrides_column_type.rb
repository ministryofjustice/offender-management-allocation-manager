class UpdateOverridesColumnType < ActiveRecord::Migration[5.2]
  def up
    rename_column :overrides, :override_reason, :override_reasons
    change_column :overrides, :override_reasons, :string, using: "override_reasons::character varying[]"
  end

  def down
    change_coloumn :overrides, :override_reasons, :string
    rename_column :overrides, :override_reasons, :override_reason
  end
end
