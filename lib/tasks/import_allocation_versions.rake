# frozen_string_literal: true

require 'rake'

namespace :import do
  namespace :allocation_versions do
    desc 'Creates flat versions (YAML-exploded) from PaperTrail records'
    task run: :environment do
      ImportAllocationVersions.new.call
    end
  end
end
