module NewMpcLinkOverrides
  NEW_MPC_URI = URI.parse(Rails.configuration.new_mpc_host).freeze

  # do not include `_path` or `_url` suffixes
  MIGRATED_LINKS = [
    :prison_parole_cases,
  ].freeze

  def self.included(base)
    base.class_eval do
      MIGRATED_LINKS.each do |method_name|
        define_method(:"#{method_name}_url") do |*args|
          new_mpc_links? ? super(*args, new_mpc_url_config) : super(*args)
        end

        define_method(:"#{method_name}_path") do |*args|
          new_mpc_links? ? send(:"#{method_name}_url", *args) : super(*args)
        end
      end

      def new_mpc_links?
        FeatureFlags.new_mpc_links.enabled?
      end

      def new_mpc_url_config
        { protocol: NEW_MPC_URI.scheme, host: NEW_MPC_URI.host, port: NEW_MPC_URI.port }.freeze
      end
    end
  end
end

Rails.application.config.to_prepare do
  Rails.application.routes.url_helpers.include(NewMpcLinkOverrides)
end
