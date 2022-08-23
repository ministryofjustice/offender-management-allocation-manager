class CnlDeactivation
  attr_reader :dry_run, :inactivated_count, :silent

  def initialize(dry_run: true, silent: false)
    @dry_run = dry_run
    @silent = silent
  end

  def call
    @inactivated_count = 0
    womens_prisons = Prison.where(code: PrisonService::WOMENS_PRISON_CODES)
    womens_prisons_count = womens_prisons.size
    report_puts "Processing #{womens_prisons_count} women's prisons. Dry run: #{dry_run}"

    womens_prisons.each_with_index do |prison, i|
      offenders = prison.offenders
      offender_count = offenders.size
      report_puts "Prison #{i + 1}/#{womens_prisons_count}: #{prison.name}: processing #{offender_count} offenders"

      offenders.each_with_index do |offender, j|
        process_offender(offender.offender_no, j + 1, offender_count)
      end
    end

    report_puts "\nDone. Complexity of need level inactivated for #{inactivated_count} offenders"
  end

  def process_offender(offender_id, offender_index, offender_count)
    report_print '.'
    nomis_offender = with_retries { HmppsApi::PrisonApi::OffenderApi.get_offender(offender_id) }

    unless nomis_offender.sentenced?
      report_print "\n#{offender_index}/#{offender_count}: #{offender_id} need to de-activate CNL"

      unless dry_run
        report_print ' - de-activating CNL'

        begin
          with_retries { HmppsApi::ComplexityApi.inactivate(offender_id) }
          @inactivated_count += 1
          report_print ' - done'
        rescue Faraday::ResourceNotFound
          report_print ' - resource not found'
        end
      end

      report_puts
    end
  end

  def with_retries(pause_secs: 10, retry_limit: 3)
    retry_limit.times do |i|
      return yield
    rescue Faraday::ServerError
      if (i + 1) == retry_limit
        report_puts "API error: #{retry_limit} re-try limit reached"
        raise
      end

      report_puts "\nAPI error. Pausing #{pause_secs}s before re-trying"
      sleep pause_secs
    end
  end

private

  def report_puts(msg = nil)
    $stdout.puts msg unless silent
  end

  def report_print(msg = nil)
    $stdout.print msg unless silent
  end
end
