# frozen_string_literal: true

require 'rake'

namespace :update_allocation_names do
  desc 'Update allocation names where they are missing'
  task process: :environment do
    if defined?(Rails) && Rails.env.development?
      Rails.logger = Logger.new(STDOUT)
    end

    username_cache = {}
    pom_cache = {}

    allocations = Allocation.where(created_by_name: nil)

    allocations.each { |allocation|
      if pom_cache.key?(allocation.nomis_staff_id)
        pom_name = pom_cache[allocation.nomis_staff_id]
      else
        pom_firstname, pom_secondname =
          PrisonOffenderManagerService.get_pom_name(allocation.nomis_staff_id)
        pom_name = "#{pom_firstname} #{pom_secondname}"
        pom_cache[allocation.nomis_staff_id] = pom_name
      end

      if username_cache.key?(allocation.created_by)
        user_name = username_cache[allocation.created_by]
      else
        begin
          user_firstname, user_secondname =
            PrisonOffenderManagerService.get_user_name(allocation.created_by)
        rescue
          user_firstname, user_secondname = [allocation.created_by, ""]
        end

        user_name = "#{user_firstname} #{user_secondname}"
        username_cache[allocation.created_by] = user_name
      end

      allocation.pom_name = pom_name
      allocation.created_by_name = user_name
      allocation.save!
    }
  end
end
