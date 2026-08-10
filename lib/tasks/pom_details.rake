# frozen_string_literal: true

require 'rake'
require 'pom_details_cleaner'

namespace :pom_details do
  desc 'Delete active zero-working-pattern PomDetails. Usage: rake pom_details:delete_auto_created or rake pom_details:delete_auto_created[FDI]'
  task :delete_auto_created, [:prison_code] => :environment do |_task, args|
    PomDetailsCleaner.new(prison_code: args[:prison_code].presence || ENV['PRISON_CODE']).call
  end
end
