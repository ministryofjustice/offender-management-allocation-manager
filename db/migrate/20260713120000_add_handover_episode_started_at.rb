# frozen_string_literal: true

class AddHandoverEpisodeStartedAt < ActiveRecord::Migration[7.2]
  def change
    add_column :handover_progress_checklists, :handover_episode_started_at, :date, null: true
  end
end
