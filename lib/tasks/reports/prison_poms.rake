# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report of all POMs in each prison'
  task prison_poms: :environment do
    require 'csv'

    CSV.open('prison_poms.csv', 'wb') do |csv|
      csv << %w[prison_code prison_name staff_id position status pom_last_name pom_first_name pom_email]

      Prison.active.each do |prison|
        puts "Obtaining POMs for #{prison.name} (#{prison.code})"

        poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison.code)

        poms.each do |pom|
          staff_detail = HmppsApi::NomisUserRolesApi.staff_details(pom.staff_id)

          csv << [
            prison.code,
            prison.name,
            pom.staff_id,
            pom.position,
            staff_detail.status,
            staff_detail.last_name,
            staff_detail.first_name,
            staff_detail.email_address
          ]
        end
      end
    end

    puts 'Report complete'
  end
end
