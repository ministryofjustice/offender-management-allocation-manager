module HostEnv
  # Update if more environments are needed
  NAMED_ENVIRONMENTS = [
    LOCAL = 'local'.freeze,
    TEST = 'test'.freeze, # this is not the `test` namespace, this is when running the tests
    STAGING = 'staging'.freeze,
    PREPROD = 'preprod'.freeze,
    PRODUCTION = 'production'.freeze,
  ].freeze

  class << self
    NAMED_ENVIRONMENTS.each { |name| delegate "#{name}?", to: :inquiry }

    def env_name
      return TEST  if Rails.env.test?
      return LOCAL if Rails.env.development?

      ENV.fetch('ENV_NAME')
    end

  private

    def inquiry
      env_name.inquiry
    end
  end
end
