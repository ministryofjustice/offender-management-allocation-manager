# frozen_string_literal: true

require 'rake'
require 'csv'

namespace :reports do
  desc 'Create a CSV report listing counds of allocated tier A & B by prison code'
  task high_risk_cases_for_probation_poms: :environment do
    prisons_range = ENV.fetch('PRISONS_RANGE', '0').split('..').map(&:to_i)
    prisons_range = Range.new(prisons_range[0], prisons_range[1])
    filename = ENV.fetch('FILENAME', 'high_risk_cases_for_probation_poms.csv')

    CSV.open(filename, 'wb') do |csv|
      csv << %w[prison total_supporting total_responsible total]

      Prison.active.order(name: :asc)[prisons_range].each do |prison|
        puts ">> Obtaining cases for #{prison.name} (#{prison.code})"

        supporting, responsible, total = results_for_prison(prison)

        csv << ["#{prison.code} - #{prison.name}", supporting, responsible, total]
      end
    end

    puts 'Report complete'
  end
end

def results_for_prison(prison)
  allocated_high_tiers = AllocationHistory
    .active_allocations_for_prison(prison.code)
    .joins('join omic_eligibilities using(nomis_offender_id)')
    .joins('join case_information using(nomis_offender_id)')
    .where("case_information.tier in ('A', 'B') and case_information.crn is not null and omic_eligibilities.eligible = true")
    .pluck(:nomis_offender_id, 'case_information.crn')
    .to_h

  pom_roles = CalculatedHandoverDate
    .where(nomis_offender_id: allocated_high_tiers.keys)
    .joins('left join responsibilities using(nomis_offender_id)')
    .pluck(
      Arel.sql(
        "calculated_handover_dates.nomis_offender_id, (
          case
          when coalesce(value, responsibility) in ('Probation', 'Community') then 'supporting'
          when coalesce(value, responsibility) in ('Prison', 'CustodyOnly', 'CustodyWithCom') then 'responsible'
          end
        ) as pom_role"
      )
    )
    .to_h

  supporting = 0
  responsible = 0
  total = 0

  allocated_high_tiers.each do |(nomis_offender_id, crn)|
    next unless HmppsApi::AssessRisksAndNeedsApi
      .get_rosh_summary(crn)
      .dig('summary', 'overallRiskLevel')
      .in?(['HIGH', 'VERY_HIGH'])

    supporting += 1 if pom_roles[nomis_offender_id] == 'supporting'
    responsible += 1 if pom_roles[nomis_offender_id] == 'responsible'
    total += 1
  rescue StandardError
    next
  end

  [supporting, responsible, total]
end
