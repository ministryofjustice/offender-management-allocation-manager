# frozen_string_literal: true

require 'rake'

namespace :emails do
  desc 'Purge email history for a given event'
  task :purge_event_history, [:event] => [:environment] do |_task, args|
    event = args[:event]

    if event.present?
      total = EmailHistory.where(event:).count
      puts "Purging email history for event '#{event}'. Total found: #{total}"
      EmailHistory.where(event:).delete_all
      puts 'Done.'
    else
      puts 'No event provided. Use: rake "emails:purge_event_history[event_name]"'
    end
  end
end
