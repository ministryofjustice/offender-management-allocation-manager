Shoryuken.configure_server do |config|
  # NOTE: this entire block is only run by the processor, so we don't overwrite
  #       the logger when the app is running as usual.

  Shoryuken::Logging.logger.formatter = lambda do |severity, datetime, _, msg|
    "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity.ljust(5)}: #{msg}\n"
  end
  Rails.logger = Shoryuken::Logging.logger

  localstack_url = ENV['LOCALSTACK_URL']
  if localstack_url.present?
    config.sqs_client = Aws::SQS::Client.new(
      endpoint: localstack_url,
      verify_checksums: false,
    )
  end
end
