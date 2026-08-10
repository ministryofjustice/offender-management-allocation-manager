# frozen_string_literal: true

class PomDetailsCleaner
  BATCH_SIZE = 1_000

  def initialize(prison_code: nil, output: $stdout)
    @prison_code = prison_code.presence
    @output = output
  end

  def call
    prisons.each { |prison| delete_for_prison!(prison) }
  end

private

  attr_reader :prison_code, :output

  def prisons
    return [Prison.find_by!(code: prison_code)] if prison_code.present?

    Prison.order(code: :asc).to_a
  end

  def delete_for_prison!(prison)
    scope = prison.pom_details.where(status: 'active', working_pattern: 0.0)
    candidate_ids = scope.distinct.pluck(:nomis_staff_id)

    if candidate_ids.empty?
      output.puts "[PomDetails] #{prison.code}: no active zero-working-pattern PomDetails found"
      return
    end

    nomis_staff_ids = nomis_staff_ids_for(prison.code)
    if nomis_staff_ids.nil?
      output.puts "[PomDetails] #{prison.code}: skipped because NOMIS lookup failed"
      return
    end

    keep_ids = candidate_ids & nomis_staff_ids.to_a
    delete_ids = candidate_ids - keep_ids

    if delete_ids.empty?
      output.puts "[PomDetails] #{prison.code}: no deletions; all #{candidate_ids.size} candidates are still returned by NOMIS"
      return
    end

    deleted_count = 0
    delete_ids.each_slice(BATCH_SIZE) do |batch_ids|
      deleted_count += scope.where(nomis_staff_id: batch_ids).delete_all
    end

    output.puts "[PomDetails] Deleted #{deleted_count} PomDetails for #{prison.code}"
    output.puts "[PomDetails] Skipped #{keep_ids.size} PomDetails still returned by NOMIS for #{prison.code}: #{keep_ids.join(', ')}" if keep_ids.any?
  end

  def nomis_staff_ids_for(prison_code)
    HmppsApi::PrisonApi::PrisonOffenderManagerApi.list(prison_code)
      .select { |pom| pom.prison_officer? || pom.probation_officer? }
      .map(&:staff_id)
      .to_set
  rescue StandardError => e
    output.puts "[PomDetails] NOMIS check failed for #{prison_code}: #{e.class}: #{e.message}"
    nil
  end
end
