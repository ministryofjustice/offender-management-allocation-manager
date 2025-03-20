# frozen_string_literal: true

class UrlMigrator
  include Singleton

  def initialize
    @url_handler = UrlHandler.new(host: host)
  end

  class UrlHandler
    include Rails.application.routes.url_helpers
    attr_reader :host

    def initialize(host:)
      @host = host
    end

    def default_url_options
      { host: }
    end
  end

  class << self
    delegate :method_missing, :respond_to?, to: :instance

    def reset!
      Singleton.__init__(self)
    end
  end

  def method_missing(name, *args)
    @url_handler.respond_to?(name) ? generate_url_for(name, *args) : super
  end

  def respond_to_missing?(name, _include_private = false)
    @url_handler.respond_to?(name) || super
  end

private

  def generate_url_for(name, *args)
    path_or_url = @url_handler.send(name, *args)
    return path_or_url unless new_mpc_links?

    # when using this migrator, we always want to generate full URLs
    # if the feature flag is enabled, even when calling `_path` methods,
    name.end_with?('_path') ? path_or_url.prepend(host) : path_or_url
  end

  def new_mpc_links?
    FeatureFlags.new_mpc_links.enabled?
  end

  def host
    if new_mpc_links?
      Rails.configuration.new_mpc_host
    else
      Rails.configuration.allocation_manager_host
    end
  end
end
