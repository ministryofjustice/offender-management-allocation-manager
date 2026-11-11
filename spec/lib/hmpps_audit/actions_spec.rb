require 'rails_helper'

RSpec.describe HmppsAudit::Actions do
  describe 'config/hmpps_audit.yml' do
    routed_actions = Rails.application.routes.routes.filter_map { |route|
      controller_path, action = route.defaults.values_at(:controller, :action)
      controller = "#{controller_path}_controller".camelize.safe_constantize if controller_path && action
      "#{controller_path}##{action}" if controller && controller < ApplicationController
    }.uniq

    it 'declares every routed action as audited, exempt or todo' do
      missing = routed_actions - described_class.all.keys

      expect(missing).to be_empty, "Declare these actions in config/hmpps_audit.yml: #{missing.join(', ')}"
    end

    it 'only declares routed actions defined in their controllers' do
      invalid = described_class.all.keys.reject do |key|
        controller_path, action = key.split('#')
        routed_actions.include?(key) && "#{controller_path}_controller".camelize.constantize.action_methods.include?(action)
      end

      expect(invalid).to be_empty, "Remove or fix these in config/hmpps_audit.yml: #{invalid.join(', ')}"
    end
  end

  describe '.find' do
    it 'returns the audit declared for a controller action' do
      expect(described_class.find('prisoners', 'search')).to eq(
        what: 'SEARCH_PRISONER', subject_type: 'SEARCH_TERM', subject_id: 'q', query_params: %w[page],
        results: { collections: %w[user_allocations offenders], id: 'offender_no' }
      )
    end

    it 'returns nil for an exempt action' do
      expect(described_class.find('health', 'ping')).to be_nil
    end

    it 'returns nil for an action still to evaluate' do
      allow(described_class).to receive(:all).and_return(described_class.parse('a#b' => { 'todo' => true }))

      expect(described_class.find('a', 'b')).to be_nil
    end

    it 'raises for an undeclared action' do
      expect { described_class.find('prisoners', 'unknown') }.to raise_error(
        described_class::UndeclaredActionError, 'Declare prisoners#unknown in config/hmpps_audit.yml as audited or exempt'
      )
    end
  end

  describe '.parse' do
    let(:audit) { { 'what' => 'VIEW_A', 'subject_type' => 'NOT_APPLICABLE' } }

    it 'accepts configured collections and an ID method name' do
      config = audit.merge('results' => { 'collections' => %w[cases recent_cases], 'id' => 'offender_no' })

      expect(described_class.parse('a#b' => config).fetch('a#b')[:results]).to eq(
        collections: %w[cases recent_cases], id: 'offender_no'
      )
    end

    it 'rejects results that are not a mapping' do
      [nil, 'offenders'].each do |results|
        expect { described_class.parse('a#b' => audit.merge('results' => results)) }
          .to raise_error(ArgumentError, /Invalid audit `results` for a#b/)
      end
    end

    it 'requires collection names and a single ID method name' do
      [
        {},
        { 'collections' => [], 'id' => 'id' },
        { 'collections' => ['offenders'], 'id' => [] },
        { 'collections' => 'offenders', 'id' => 'id' },
        { 'collections' => ['offenders'], 'id' => [nil] },
        { 'collections' => [' '], 'id' => 'id' },
        { 'collections' => ['offenders'], 'id' => ' ' },
        { 'collections' => ['offenders'], 'id' => %w[offender offender_no] },
      ].each do |results|
        expect { described_class.parse('a#b' => audit.merge('results' => results)) }
          .to raise_error(ArgumentError, /Invalid audit `results\.(collections|id)` for a#b/)
      end
    end

    it 'defaults optional settings' do
      expect(described_class.parse('a#b' => { 'what' => 'VIEW_A', 'subject_type' => 'NOT_APPLICABLE' })).to eq(
        'a#b' => { what: 'VIEW_A', subject_type: 'NOT_APPLICABLE', subject_id: nil, query_params: [] }
      )
    end

    it 'accepts an exemption with a reason' do
      expect(described_class.parse('a#b' => { 'exempt' => 'No user data' })).to eq('a#b' => { exempt: 'No user data' })
    end

    it 'rejects an exemption without a reason' do
      expect { described_class.parse('a#b' => { 'exempt' => '' }) }
        .to raise_error(ArgumentError, 'Missing exemption reason for a#b')
    end

    it 'rejects an exemption that also declares an audit' do
      expect { described_class.parse('a#b' => { 'exempt' => 'No user data', 'what' => 'VIEW_A' }) }
        .to raise_error(ArgumentError, 'Exempt a#b must not declare an audit')
    end

    it 'rejects a missing event name' do
      expect { described_class.parse('a#b' => { 'subject_type' => 'NOT_APPLICABLE' }) }
        .to raise_error(ArgumentError, 'Missing audit `what` for a#b')
    end

    it 'rejects an unsupported subject type' do
      expect { described_class.parse('a#b' => { 'what' => 'VIEW_A', 'subject_type' => 'NOMS' }) }
        .to raise_error(ArgumentError, 'Unsupported audit subject type `NOMS` for a#b')
    end
  end
end
