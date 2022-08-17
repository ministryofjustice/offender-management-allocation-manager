class CnlDeactivation
  attr_reader :dry_run, :inactivated_count

  def initialize(dry_run: true)
    @dry_run = dry_run
  end

  def call
    @inactivated_count = 0
    womens_prisons = Prison.where(code: PrisonService::WOMENS_PRISON_CODES)
    womens_prisons_count = womens_prisons.size
    puts "Processing #{womens_prisons_count} women's prisons. Dry run: #{dry_run}"

    womens_prisons.each_with_index do |prison, i|
      offenders = prison.offenders
      offender_count = offenders.size
      puts "Prison #{i + 1}/#{womens_prisons_count}: #{prison.name}: processing #{offender_count} offenders"

      offenders.each_with_index do |offender, j|
        process_offender(offender.nomis_offender_id, j + 1, offender_count)
      end
    end

    puts "\nDone. Complexity of need level inactivated for #{inactivated_count} offenders"
  end

  def process_offender(offender_id, offender_index, offender_count)
    print '.'
    nomis_offender = with_retries { HmppsApi::PrisonApi::OffenderApi.get_offender(offender_id) }

    unless nomis_offender.sentenced?
      print "\n#{offender_index}/#{offender_count}: #{offender_id} need to de-activate CNL"

      unless dry_run
        print ' - de-activating CNL'

        begin
          with_retries { HmppsApi::ComplexityApi.inactivate(offender_id) }
          @inactivated_count += 1
          print ' - done'
        rescue Faraday::ResourceNotFound
          print ' - resource not found'
        end
      end

      puts
    end
  end

  def with_retries(pause_secs: 10, retry_limit: 3)
    retry_limit.times do |i|
      return yield
    rescue Faraday::ServerError
      if (i + 1) == retry_limit
        puts "API error: #{retry_limit} re-try limit reached"
        raise
      end

      puts "\nAPI error. Pausing #{pause_secs}s before re-trying"
      sleep pause_secs
    end
  end
end
