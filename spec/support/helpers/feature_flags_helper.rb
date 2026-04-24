module FeatureFlagsHelper
  def stub_feature_flag(name, enabled: true)
    allow(FeatureFlags).to receive(name).and_return(
      instance_double(FeatureFlags::EnabledFeature, enabled?: enabled, disabled?: !enabled)
    )
  end
end

RSpec.configure do |config|
  config.include(FeatureFlagsHelper)
end
