require 'rails_helper'

RSpec.describe HmppsAudit::Actions do
  describe 'config/hmpps_audit.yml' do
    routed_actions = Rails.application.routes.routes.filter_map { |route|
      controller_path, action = route.defaults.values_at(:controller, :action)
      controller = "#{controller_path}_controller".camelize.safe_constantize if controller_path && action
      "#{controller_path}##{action}" if controller && controller < ApplicationController
    }.uniq

    # Routed actions not yet declared as audited or exempt.
    # Remove actions from this list as they're declared; it must end up empty
    undeclared_actions = %w[
      allocation_retentions#create
      allocation_retentions#new
      allocation_staff#check_compare_list
      allocation_staff#compare_poms
      allocation_staff#index
      allocations#history
      build_allocations#new
      build_allocations#show
      build_allocations#update
      case_information#create
      case_information#edit
      case_information#new
      case_information#update
      caseload#cases
      caseload#index
      caseload#new_cases
      caseload#parole_cases
      caseload#updates_required
      caseload_global#index
      complexity_levels#edit
      complexity_levels#update
      coworking#confirm
      coworking#confirm_removal
      coworking#create
      coworking#destroy
      debugging#debugging
      debugging#timeline
      early_allocations#confirm_with_reason
      early_allocations#discretionary
      early_allocations#edit
      early_allocations#eligible
      early_allocations#index
      early_allocations#new
      early_allocations#oasys_date
      early_allocations#show
      early_allocations#update
      female_missing_infos#new
      female_missing_infos#update
      handover_progress_checklists#edit
      handover_progress_checklists#update
      handovers#com_allocation_overdue
      handovers#in_progress
      handovers#overdue_tasks
      handovers#upcoming
      handovers/email_preferences#edit
      handovers/email_preferences#update
      manage/audit_events#index
      manage/deallocate_poms#confirm
      manage/deallocate_poms#search
      manage/deallocate_poms#update
      manage/handover_changes#historic
      manage/handover_changes#live
      onboarding#check_answers
      onboarding#confirmation
      onboarding#error
      onboarding#position
      onboarding#search
      onboarding#working_pattern
      parole_cases#index
      parole_reviews#edit
      parole_reviews#update
      poms#confirm_delete
      poms#confirm_removal
      poms#destroy
      poms#edit
      poms#index
      poms#reallocate
      poms#show
      poms#show_non_pom
      poms#update
      prisoners#allocated
      prisoners#missing_information
      prisoners#review_allocations
      prisoners#review_case_details
      prisoners#review_changes
      prisoners#unallocated
      reallocations/journey#complete
      reallocations/journey#confirmation
      reallocations/journey#override
      reallocations/journey#summary
      reallocations/journey#update_override
      reallocations/selection#caseload
      reallocations/selection#check_compare_list
      reallocations/selection#compare_poms
      reallocations/selection#create
      reallocations/selection#error
      reallocations/selection#index
      responsibilities#confirm
      responsibilities#confirm_removal
      responsibilities#create
      responsibilities#destroy
      responsibilities#new
      victim_liaison_officers#create
      victim_liaison_officers#delete
      victim_liaison_officers#destroy
      victim_liaison_officers#edit
      victim_liaison_officers#new
      victim_liaison_officers#update
    ]

    it 'declares every routed action as audited or exempt, apart from known gaps' do
      missing = routed_actions - described_class.all.keys - undeclared_actions

      expect(missing).to be_empty, "Declare these actions in config/hmpps_audit.yml: #{missing.join(', ')}"
    end

    it 'only lists known gaps that are routed and not yet declared' do
      stale = undeclared_actions - (routed_actions - described_class.all.keys)

      expect(stale).to be_empty, "Remove these from undeclared_actions: #{stale.join(', ')}"
    end

    described_class.all.each_key do |key|
      it "declares #{key} as a routed action of an audited controller" do
        controller_path, action = key.split('#')
        controller = "#{controller_path}_controller".camelize.constantize

        expect(controller).to include(HmppsAuditing)
        expect(controller.action_methods).to include(action)
        expect(routed_actions).to include(key)
      end
    end
  end

  describe '.find' do
    it 'returns the audit declared for a controller action' do
      expect(described_class.find('prisoners', 'search')).to eq(
        what: 'SEARCH_PRISONER', subject_type: 'SEARCH_TERM', subject_id: 'q', query_params: %w[prison_id page]
      )
    end

    it 'returns nil for an exempt action' do
      expect(described_class.find('health', 'ping')).to be_nil
    end

    it 'returns nil for an undeclared action' do
      expect(described_class.find('prisoners', 'index')).to be_nil
    end
  end

  describe '.parse' do
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
