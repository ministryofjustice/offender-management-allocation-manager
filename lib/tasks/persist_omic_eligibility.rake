desc 'Persist the omic eligibility for each offender in each prison, to aid with DPR queries'
task persist_omic_eligibility: :environment do
  Rails.logger = Logger.new($stdout) if Rails.env.production?
  Rails.logger.info('Persisting OMiC eligibility')

  start_time = Time.zone.now

  PrisonService.prison_codes.each do |code|
    Rails.logger.info("Persisting OMiC eligibility - Prison: #{code}")

    PersistOmicEligibility.for_offenders_at(code)
  end

  PersistOmicEligibility.cleanup_records_updated_before(start_time)

  Rails.logger.info('Persisting OMiC eligibility - completed!')
end
