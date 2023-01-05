class CnlDeactivation
  attr_reader :dry_run, :inactivated_count

  def initialize(dry_run: true)
    @dry_run = dry_run
  end

  def call
    if defined?(Rails) && !Rails.env.production?
      Rails.logger = Logger.new($stdout)
    end

    @inactivated_count = 0
    womens_prisons = Prison.where(code: PrisonService::WOMENS_PRISON_CODES)
    womens_prisons_count = womens_prisons.size
    Rails.logger.info "#{self.class}: Processing #{womens_prisons_count} women's prisons. Dry run: #{dry_run}"

    womens_prisons.each_with_index do |prison, i|
      offenders = prison.offenders
      offender_count = offenders.size
      Rails.logger.info "#{self.class}: Prison #{i + 1}/#{womens_prisons_count}: #{prison.name}: processing #{offender_count} offenders"

      offenders.each_with_index do |offender, j|
        process_offender(offender.offender_no, j + 1, offender_count)
      end
    end

    Rails.logger.info "#{self.class}: Done. Complexity of need level de-activated for #{inactivated_count} offenders"
  end

  def process_offender(offender_id, offender_index, offender_count)
    nomis_offender = with_retries { HmppsApi::PrisonApi::OffenderApi.get_offender(offender_id, ignore_legal_status: true) }

    unless nomis_offender.sentenced?
      output = ["#{self.class}: - #{offender_index}/#{offender_count}: #{offender_id} is un-sentenced"]

      unless dry_run
        output << ' - de-activating CNL'

        begin
          with_retries { HmppsApi::ComplexityApi.inactivate(offender_id) }
          @inactivated_count += 1
          output << ' - done'
        rescue Faraday::ResourceNotFound
          output << ' - resource not found'
        end
      end

      Rails.logger.info output.join
    end
  end

  def with_retries(pause_secs: 10, retry_limit: 3)
    retry_limit.times do |i|
      return yield
    rescue Faraday::ServerError
      if (i + 1) == retry_limit
        Rails.logger.error "#{self.class}: API error: #{retry_limit} re-try limit reached"
        raise
      end

      Rails.logger.info "#{self.class}: API error. Pausing #{pause_secs}s before re-trying"
      sleep pause_secs
    end
  end
end
