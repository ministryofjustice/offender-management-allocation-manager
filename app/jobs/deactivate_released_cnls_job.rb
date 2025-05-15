class DeactivateReleasedCnlsJob < ApplicationJob
  queue_as :default

  attr_reader :prison, :inactivated_count, :errors_count

  def perform(prison)
    @prison = prison
    @inactivated_count = 0
    @errors_count = 0

    offenders = HmppsApi::PrisonApi::OffenderApi.get_offenders_out_of_prison(prison.code)
    offender_count = offenders.size
    log("Processing #{offender_count} released offenders...")

    offenders.each do |offender|
      process_offender(offender)
    end

    log("Done. Inactivated: #{inactivated_count}/#{offender_count}. Errors: #{errors_count}.")
  end

private

  def process_offender(nomis_offender)
    with_retries { HmppsApi::ComplexityApi.inactivate(nomis_offender.offender_no) }
    @inactivated_count += 1
  rescue StandardError => e
    log("Offender ID #{nomis_offender.offender_no} produced an error: #{e.message}")
    @errors_count += 1
  end

  def with_retries(pause_secs: 5, retry_limit: 3)
    retry_limit.times do |i|
      return yield
    rescue Faraday::ServerError
      if (i + 1) == retry_limit
        log("API error: #{retry_limit} re-try limit reached")
        raise
      end

      log("API error. Pausing #{pause_secs}s before re-trying")
      sleep pause_secs
    end
  end

  def log(msg)
    logger.info("[#{self.class.name}] [#{prison.code}] #{msg}")
  end

  def logger
    @logger ||= Logger.new($stdout)
  end
end
