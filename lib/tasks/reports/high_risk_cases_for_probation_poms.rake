# frozen_string_literal: true

require 'rake'
require 'csv'

CSV_COLUMNS = %w[
  prison
  poms_supporting
  probation_poms_supporting
  prison_poms_supporting
  poms_responsible
  probation_poms_responsible
  prison_poms_responsible
  total
].freeze

namespace :reports do
  desc 'Create a CSV report listing counds of allocated tier A & B by prison code'
  task high_risk_cases_for_probation_poms: :environment do
    prisons_range = ENV.fetch('PRISONS_RANGE', '0').split('..').map(&:to_i)
    prisons_range = Range.new(prisons_range[0], prisons_range[1])

    results = in_batches(Prison.active.order(name: :asc)[prisons_range], 2) do |prison|
      puts ">> Obtaining cases for #{prison.name} (#{prison.code})"

      results_for_prison(prison)
    end

    filename = ENV.fetch('FILENAME', 'high_risk_cases_for_probation_poms.csv')
    CSV.open(filename, 'wb') do |csv|
      csv << CSV_COLUMNS

      results.sort_by(&:first).each { |row| csv << row }
    end

    puts 'Report complete'
  end
end

def results_for_prison(prison)
  allocated_high_tier_offenders = allocated_high_tier_offenders_at(prison)
  pom_roles = pom_roles_for(allocated_high_tier_offenders.map(&:first))
  pom_positions = pom_positions_at(prison)

  row = Row.new
  row.prison = "#{prison.code} - #{prison.name}"

  high_rosh_offenders_of(allocated_high_tier_offenders).each do |(nomis_offender_id, primary_pom_nomis_id)|
    if pom_roles[nomis_offender_id] == 'supporting'
      row.poms_supporting += 1
      row.probation_poms_supporting += 1 if pom_positions[primary_pom_nomis_id] == RecommendationService::PROBATION_POM
      row.prison_poms_supporting += 1 if pom_positions[primary_pom_nomis_id] == RecommendationService::PRISON_POM
    end

    if pom_roles[nomis_offender_id] == 'responsible'
      row.poms_responsible += 1
      row.probation_poms_responsible += 1 if pom_positions[primary_pom_nomis_id] == RecommendationService::PROBATION_POM
      row.prison_poms_responsible += 1 if pom_positions[primary_pom_nomis_id] == RecommendationService::PRISON_POM
    end

    row.total += 1
  end

  row.as_csv
end

def high_rosh_offenders_of(allocated_high_tier_offenders)
  # The slow bit of this job is checking ROSH for EVERY offender
  # this makes it slightly better by checking in batches on different threads
  in_batches(allocated_high_tier_offenders, 5) do |(nomis_offender_id, crn, primary_pom_nomis_id)|
    is_high_rosh?(crn) ? [nomis_offender_id, primary_pom_nomis_id] : nil
  end
end

def allocated_high_tier_offenders_at(prison)
  AllocationHistory
    .active_allocations_for_prison(prison.code)
    .joins('join omic_eligibilities using(nomis_offender_id)')
    .joins('join case_information using(nomis_offender_id)')
    .where("case_information.tier in ('A', 'B') and case_information.crn is not null and omic_eligibilities.eligible = true")
    .pluck(:nomis_offender_id, 'case_information.crn', :primary_pom_nomis_id)
end

def pom_roles_for(offender_ids)
  CalculatedHandoverDate
    .where(nomis_offender_id: offender_ids)
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
end

def pom_positions_at(prison)
  HmppsApi::PrisonApi::PrisonOffenderManagerApi
    .list(prison.code)
    .map { [it.staff_id, it.position] }
    .to_h
end

def is_high_rosh?(crn)
  HmppsApi::AssessRisksAndNeedsApi
    .get_rosh_summary(crn)
    .dig('summary', 'overallRiskLevel')
    .in?(['HIGH', 'VERY_HIGH'])
rescue StandardError
  false
end

def in_batches(things, batch_size)
  # slice the given array of things into X (batch_size) chunks
  # then spawn a thread for each in the current chunk
  # then join threads and return the non null values as a flat array
  things.each_slice(batch_size).flat_map do |batch|
    threads = batch.map do |args|
      Thread.new do
        yield args
      end
    end
    threads.map(&:value).compact
  end
end

class Row
  attr_accessor(*CSV_COLUMNS)

  def initialize = CSV_COLUMNS.each { instance_variable_set "@#{it}", 0 }
  def as_csv = CSV_COLUMNS.map { send(it) }
end
