class RemoveFlipFlopFeaturesTable < ActiveRecord::Migration[7.1]
  def up
    drop_table :flipflop_features
  end
end
