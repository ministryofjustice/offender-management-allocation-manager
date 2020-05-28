class AddShadowCodeIndexToTeams < ActiveRecord::Migration[6.0]
  def change
    add_index :teams, :shadow_code
  end
end
