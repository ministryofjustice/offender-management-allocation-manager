class AddShadowCodeToTeam < ActiveRecord::Migration[6.0]
  def change
    change_table :teams do |t|
      t.string :shadow_code
      t.references :local_divisional_unit
    end
  end
end
