# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubjectAccessRequestReport do
  before do
    allow(Rails.application.config.x).to receive(:sar_report_version).and_return('v1-r1')
  end

  describe 'DB schema change guard' do
    # Keep this updated once any potential SAR drifting is asserted
    let(:reviewed_version) { '20261117_111500' }

    let(:current_version) { ActiveRecord::Base.connection_pool.migration_context.current_version }
    let(:message) do
      <<~MESSAGE
        A new migration has been added: #{current_version}

        Review all SAR payload versions and template revisions before updating this guard version,
        not just the one currently configured.
        Check:
        - config/templates/*_sar_template.mustache
        - app/services/sar_offender_data_service_v*.rb
        - spec/services/sar_offender_data_service_v*_spec.rb
        - spec/api/sar_api_spec.rb
        - spec/api/sar_template_api_spec.rb
      MESSAGE
    end

    it 'requires a SAR template and payload review when the DB schema changes' do
      expect(current_version).to eq(reviewed_version.to_i), message
    end
  end

  describe '.validate_configuration!' do
    subject(:validate_configuration!) { described_class.validate_configuration! }

    it 'does not raise when the template exists' do
      expect { validate_configuration! }.not_to raise_error
    end

    context 'when the template path does not exist' do
      before do
        allow(described_class).to receive(:template_path).and_return(Pathname.new('/tmp/missing-sar.mustache'))
      end

      it 'raises a configuration error' do
        expect { validate_configuration! }
          .to raise_error(described_class::ConfigurationError, /missing-sar.mustache/)
      end
    end

    context 'when the configured revision has been retired' do
      before do
        allow(Rails.application.config.x).to receive(:sar_report_version).and_return('v1-r0')
      end

      it 'raises a configuration error rather than serving a different format' do
        expect { validate_configuration! }
          .to raise_error(described_class::ConfigurationError, /Unsupported SAR_REPORT_VERSION "v1-r0"/)
      end
    end
  end

  describe 'registered revisions' do
    expected_services = {
      'v1-r1' => SarOffenderDataServiceV1,
      'v1-r2' => SarOffenderDataServiceV1,
    }.freeze

    it 'registers the intended data service for every supported revision' do
      expect(described_class::DATA_SERVICES).to eq(expected_services)
    end

    expected_services.each do |revision, data_service|
      context "with #{revision}" do
        before do
          allow(Rails.application.config.x).to receive(:sar_report_version).and_return(revision)
        end

        it 'validates the template and dispatches to the matching data service' do
          from_date = Date.new(2020, 1, 1)
          to_date = Date.new(2020, 1, 31)
          payload = { nomsNumber: 'A1111AA' }
          service = instance_double(data_service, find: payload)
          expect(data_service).to receive(:new).with('A1111AA', from_date, to_date).and_return(service)

          expect(described_class.template_path).to eq(Rails.root.join("config/templates/#{revision}_sar_template.mustache"))
          expect { described_class.validate_configuration! }.not_to raise_error
          expect(described_class.find('A1111AA', from_date, to_date)).to eq(payload)
        end
      end
    end
  end
end
