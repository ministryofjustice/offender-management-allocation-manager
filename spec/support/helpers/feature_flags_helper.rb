module FeatureFlagsHelper
  def stub_rosh_level_feature(enabled: true)
    allow(FeatureFlags).to receive(:rosh_level).and_return(
      instance_double(FeatureFlags::EnabledFeature, enabled?: enabled)
    )
  end
end

RSpec.configure do |config|
  config.include(FeatureFlagsHelper)
end
