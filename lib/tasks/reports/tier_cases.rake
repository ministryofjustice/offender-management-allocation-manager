# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report listing the cases for POMs responsible for Tier A or B'
  task tier_cases: :environment do
    require 'csv'

    CSV.open('tier_cases.csv', 'wb') do |csv|
      csv << %w[prison_code prison_name nomis_id]

      Prison.active.order(name: :asc).each do |prison|
        puts ">> Obtaining cases for #{prison.name} (#{prison.code})"

        poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison.code)
        puts "Prison #{prison.code} has #{poms.count} POMs"

        poms.each do |pom|
          next if pom.probation_officer?

          pom_detail = PomDetail.find_by(nomis_staff_id: pom.staff_id, prison_code: prison.code, status: 'active')
          next if pom_detail.nil?

          staff_member = StaffMember.new(prison, pom.staff_id, pom_detail)
          allocations = staff_member
            .allocations
            .select(&:pom_responsible?)
            .select { |a| %w[A B].include?(a.tier) }

          allocations.each do |alloc|
            csv << [
              prison.code,
              prison.name,
              alloc.nomis_offender_id,
            ]
          end
        end
      end
    end

    puts 'Report complete'
  end
end
