require 'rails_helper'

describe FeatureFlags do
  before do
    # override whatever is in `feature_flags.yml` with these values
    # so that tests are predictable
    allow(
      described_class.instance
    ).to receive(:config).and_return(
      {
        enabled_foobar_feature: {
          staging: true,
        },
        disabled_foobar_feature: {
          local: false,
          test: false,
          staging: false,
        }
      }.with_indifferent_access
    )
  end

  describe '#enabled?' do
    context 'with test environment on local host' do
      it 'has the expected HostEnv' do
        expect(described_class.instance.env_name).to eq(HostEnv::TEST)
      end

      it 'is enabled' do
        expect(described_class.enabled_foobar_feature.enabled?).to be(true)
        expect(described_class.enabled_foobar_feature.disabled?).to be(false)
      end

      it 'is disabled' do
        expect(described_class.disabled_foobar_feature.enabled?).to be(false)
        expect(described_class.disabled_foobar_feature.disabled?).to be(true)
      end
    end

    context 'with development environment on local host' do
      before do
        allow(
          described_class.instance
        ).to receive(:env_name).and_return(HostEnv::LOCAL)
      end

      it 'has the expected HostEnv' do
        expect(described_class.instance.env_name).to eq(HostEnv::LOCAL)
      end

      it 'is enabled' do
        expect(described_class.enabled_foobar_feature.enabled?).to be(true)
      end

      it 'is disabled' do
        expect(described_class.disabled_foobar_feature.enabled?).to be(false)
      end
    end

    context 'with production environment on staging server' do
      before do
        allow(
          described_class.instance
        ).to receive(:env_name).and_return(HostEnv::STAGING)
      end

      it 'has the expected HostEnv' do
        expect(described_class.instance.env_name).to eq(HostEnv::STAGING)
      end

      it 'is enabled' do
        expect(described_class.enabled_foobar_feature.enabled?).to be(true)
      end

      it 'is disabled' do
        expect(described_class.disabled_foobar_feature.enabled?).to be(false)
      end
    end

    context 'with production environment on production server' do
      before do
        allow(
          described_class.instance
        ).to receive(:env_name).and_return(HostEnv::PRODUCTION)
      end

      it 'has the expected HostEnv' do
        expect(described_class.instance.env_name).to eq(HostEnv::PRODUCTION)
      end

      it 'is disabled as it is not explicitly declared' do
        expect(described_class.enabled_foobar_feature.enabled?).to be(false)
      end
    end
  end

  describe 'when handling of method_missing' do
    context 'with a feature defined in the config' do
      it 'responds true' do
        expect(described_class.respond_to?(:enabled_foobar_feature)).to be(true)
      end
    end

    context 'with a method defined on the superclass' do
      it 'responds true' do
        expect(described_class.respond_to?(:object_id)).to be(true)
      end
    end

    context 'with an unknown method' do
      it 'responds false' do
        expect(described_class.respond_to?(:not_a_real_feature)).to be(false)
      end

      it 'raises an exception' do
        expect { described_class.not_a_real_feature }.to raise_exception(NoMethodError)
      end
    end
  end
end
