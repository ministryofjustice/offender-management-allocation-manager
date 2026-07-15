class RemoveHandoverEpisodeStartedAt < ActiveRecord::Migration[8.1]
  def change
    remove_column :handover_progress_checklists, :handover_episode_started_at, :date, null: true
  end
end
