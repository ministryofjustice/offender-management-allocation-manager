# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubjectAccessRequestTemplateService do
  let(:template_path) { described_class.template_path }

  describe 'DB schema change guard' do
    # Keep this updated once any potential SAR drifting is asserted
    let(:reviewed_version) { '20260713_120000' }

    let(:current_version) { ActiveRecord::Base.connection_pool.migration_context.current_version }
    let(:message) do
      <<~MESSAGE
        A new migration has been added.

        Please review whether the SAR payload or template should change before updating this guard version.
        Check:
        - app/services/sar_offender_data_service.rb
        - config/templates/sar_template.mustache
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
  end

  describe '.content' do
    subject(:content) { described_class.content }

    let(:expected_content) { File.read(template_path, encoding: 'UTF-8') }

    it 'returns the template body' do
      expect(content).to eq(expected_content)
    end
  end
end
