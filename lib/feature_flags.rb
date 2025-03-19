# Determine whether a feature is enabled in this environment.
#
# usage (for e.g. feature :foobar):
#
#   FeatureFlags.foobar.enabled?
#
class FeatureFlags
  include Singleton

  attr_reader :config, :env_name

  class EnabledFeature
    ENV_DEFAULTS = {
      HostEnv::LOCAL => true,
      HostEnv::TEST => true,
    }.freeze

    def initialize(config, env_name)
      @env_config = config
      @env_name = env_name
    end

    def enabled?
      @env_config.fetch(
        @env_name, default_for(@env_name)
      )
    end

    def disabled?
      !enabled?
    end

  private

    def default_for(env)
      ENV_DEFAULTS.fetch(env, false)
    end
  end

  def initialize
    @env_name = HostEnv.env_name
    @config = YAML.load_file(
      Rails.root.join('config/feature_flags.yml')
    ).fetch('feature_flags', {}).with_indifferent_access.freeze
  end

  class << self
    delegate :method_missing, :respond_to?, to: :instance

    def reset!
      Singleton.__init__(self)
    end
  end

  def method_missing(name, *args)
    if config.key?(name)
      EnabledFeature.new(config.fetch(name), env_name)
    else
      super
    end
  end

  def respond_to_missing?(name, _include_private = false)
    config.key?(name) || super
  end
end
