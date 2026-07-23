# frozen_string_literal: true

desc 'Fetch the authoritative tier from the Tier API for all non-manual CaseInformation records with a CRN'
task refresh_tiers: :environment do
  # avoid lots of log traces from the API calls
  Rails.logger.level = :warn

  cases = CaseInformation.where(manual_entry: false).where.not(crn: nil)
  total = cases.count
  queued = 0

  puts "Queueing FetchTierJob for #{total} case information records"

  cases.in_batches(of: 1000) do |batch|
    crns = batch.pluck(:crn)

    ActiveJob.perform_all_later(
      crns.map { FetchTierJob.new(it, trigger_method: :bulk_refresh) }
    )

    queued += crns.size
    puts "event=refresh_tiers,status=enqueuing,queued=#{queued}/#{total}"
  end

  puts "event=refresh_tiers,status=complete,queued=#{queued}"
end
