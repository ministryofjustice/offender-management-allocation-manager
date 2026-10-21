# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:prison) { create(:prison).code }
  let(:poms) do
    [
      build(:pom,
            firstName: 'Alice',
            position: RecommendationService::PRISON_POM,
            staffId: 1
           )
    ]
  end

  before do
    stub_poms(prison, poms)
  end

  describe '#index' do
    {
      'SPO' => { roles: [SsoIdentity::SPO_ROLE], groups: [6, 2], flagged_groups: [7, 2] },
      'POM' => { roles: [SsoIdentity::POM_ROLE], groups: [7], flagged_groups: [7] },
      'SPO and POM' => {
        roles: [SsoIdentity::SPO_ROLE, SsoIdentity::POM_ROLE],
        groups: [6, 2, 6],
        flagged_groups: [7, 2, 6]
      }
    }.each do |role, configuration|
      context "when displaying tiles for #{role}" do
        render_views

        [false, true].each do |enabled|
          it "groups tiles by section with the change in circumstances flag #{enabled ? 'enabled' : 'disabled'}" do
            stub_sso_data(prison, staff_id: 1, roles: configuration.fetch(:roles))
            stub_feature_flag(:change_in_circumstances, enabled:)

            get :index, params: { prison_id: prison }

            page = Nokogiri::HTML(response.body)
            groups = page.css('.card-group').map { |group| group.css('.card-group__item').size }
            expect(groups).to eq(configuration.fetch(enabled ? :flagged_groups : :groups))
            expect(page.css('.card-group__item').all? { |tile| tile['class'].split.include?('govuk-grid-column-one-third') }).to be true
            expect(page.css('.card__link').map(&:text).count('Get help with this service')).to eq(1)

            if enabled && configuration.fetch(:roles).include?(SsoIdentity::SPO_ROLE)
              expect(response.body).to have_link('Review allocations', href: review_allocations_prison_prisoners_path(prison))
            else
              expect(response.body).not_to have_link('Review allocations')
            end
          end
        end
      end
    end

    context 'when the live active caseload differs from the prison in the URL', skip_active_caseload_check_stubbing: true do
      let(:prison) { create(:prison, code: 'RSI').code }

      before do
        create(:prison, code: 'LEI')
        stub_sso_data('RSI', caseloads: %w[LEI RSI])
        stub_dps_header_footer
      end

      it 'redirects to the live active caseload prison dashboard' do
        get :index, params: { prison_id: prison }

        expect(response).to redirect_to(prison_dashboard_index_path(prison_id: 'LEI'))
        expect(flash[:notice]).to eq(I18n.t('views.navigation.enforce_active_caseload', name: 'Leeds (HMP)'))
        expect(session[:sso_data]).to be_nil
      end
    end

    context 'when logged in as POM' do
      render_views

      before do
        stub_signed_in_pom(prison, 1, 'alice')
      end

      it 'shows me only Manage case tasks' do
        get :index, params: { prison_id: prison }
        expect(response).to render_template("index")

        expect(assigns(:is_pom)).to be true
        expect(assigns(:is_spo)).to be false

        aggregate_failures do
          expect(response.body).to have_content('Your cases')
          expect(response.body).to have_content('New allocations')
          expect(response.body).to have_text('View your handover cases')
          expect(response.body).to have_link('Case updates needed', href: prison_staff_caseload_updates_required_path(prison, 1))
          expect(response.body).to have_content('All allocations in this prison')

          expect(response.body).not_to have_content('All allocated cases')
          expect(response.body).not_to have_content('Make allocations')
          expect(response.body).not_to have_content('Add missing details')
          expect(response.body).not_to have_content('View all POMs')
          expect(response.body).not_to have_content('View all handover cases')
        end
      end

      it 'shows a static task description without loading prisoners or tasks' do
        get :index, params: { prison_id: prison }

        expect(response.body).to have_content('View and complete updates needed for your cases.')
      end
    end

    context 'when logged in as both SPO and POM' do
      render_views

      before do
        stub_signed_in_spo_pom(prison, 1, 'alice')
      end

      it 'shows static allocation and task descriptions without loading prisoners or tasks' do
        get :index, params: { prison_id: prison }

        expect(assigns(:is_pom)).to be true
        expect(assigns(:is_spo)).to be true
        expect(response.body).to have_content('Allocate people in this prison to POMs.')
        expect(response.body).to have_content('Missing details need to be added for these people before they can be allocated.')
        expect(response.body).to have_content('View and complete updates needed for your cases.')
      end
    end

    context 'when logged in as SPO' do
      render_views

      before do
        stub_sso_data(prison)
      end

      it 'shows me only SPO tasks' do
        get :index, params: { prison_id: prison }
        expect(response).to render_template("index")

        expect(assigns(:is_pom)).to be false
        expect(assigns(:is_spo)).to be true

        expect(response.body).not_to have_content('Your cases')
        expect(response.body).not_to have_content('New allocations')
        expect(response.body).not_to have_content('View your handover cases')
        expect(response.body).not_to have_content('Case updates needed')
        expect(response.body).not_to have_content('All allocations in this prison')

        expect(response.body).to have_content('All allocated cases')
        expect(response.body).to have_link('Make allocations', href: unallocated_prison_prisoners_path(prison))
        expect(response.body).to have_link('Add missing details', href: missing_information_prison_prisoners_path(prison))
        expect(response.body).to have_content('View all POMs')
        expect(response.body).to have_text('View all handover cases')
      end

      it 'shows static allocation descriptions without loading prisoners or tasks' do
        get :index, params: { prison_id: prison }

        expect(response.body).to have_content('Allocate people in this prison to POMs.')
        expect(response.body).to have_content('Missing details need to be added for these people before they can be allocated.')
      end
    end
  end
end
