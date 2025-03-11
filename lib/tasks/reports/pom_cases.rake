# frozen_string_literal: true

require 'rake'

namespace :reports do
  desc 'Create a CSV report with the number of cases each POM is responsible for'
  task pom_cases: :environment do
    require 'csv'

    CSV.open('pom_cases.csv', 'wb') do |csv|
      csv << %w[prison_name probation_responsible_cases prison_responsible_cases probation_all_cases prison_all_cases probation_isp_cases]

      Prison.active.each do |prison|
        puts ">> Obtaining case results for #{prison.name} (#{prison.code})"

        results = {
          probation_responsible_cases: 0,
          prison_responsible_cases: 0,
          probation_all_cases: 0,
          prison_all_cases: 0,
          probation_isp_cases: 0,
        }

        poms = HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison.code)
        puts "Prison #{prison.code} has #{poms.count} POMs"

        poms.each do |pom|
          pom_detail = PomDetail.find_by(nomis_staff_id: pom.staff_id, prison_code: prison.code, status: 'active')
          next if pom_detail.nil?

          allocations = AllocationHistory.active_pom_allocations(pom.staff_id, prison.code)

          pom_responsible_allocations_count = allocations.count { |a| a.primary_pom_nomis_id == pom.staff_id }
          total_allocations_count = allocations.count

          if pom.probation_officer?
            results[:probation_responsible_cases] += pom_responsible_allocations_count
            results[:probation_all_cases] += total_allocations_count
          elsif pom.prison_officer?
            results[:prison_responsible_cases] += pom_responsible_allocations_count
            results[:prison_all_cases] += total_allocations_count
          end

          # rubocop:disable Style/Next
          if pom.probation_officer?
            offender_nos = allocations.map(&:nomis_offender_id).uniq
            probation_isp_cases_count = OffenderService.get_offenders(offender_nos).count(&:indeterminate_sentence?)
            results[:probation_isp_cases] += probation_isp_cases_count
          end
          # rubocop:enable Style/Next
        end

        csv << [
          prison.name,
          results[:probation_responsible_cases],
          results[:prison_responsible_cases],
          results[:probation_all_cases],
          results[:prison_all_cases],
          results[:probation_isp_cases]
        ]
      end
    end

    puts 'Report complete'
  end
end
