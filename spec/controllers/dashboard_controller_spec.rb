# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DashboardController, type: :controller do
  let(:offenders) { build_list(:nomis_offender, 3) }
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
    stub_offenders_for_prison(prison, offenders)
  end

  describe '#index' do
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
          expect(response.body).to have_content('Case updates needed')
          expect(response.body).to have_content('All allocations in this prison')

          expect(response.body).not_to have_content('All allocated cases')
          expect(response.body).not_to have_content('Make allocations')
          expect(response.body).not_to have_content('Add missing details')
          expect(response.body).not_to have_content('View all POMs')
          expect(response.body).not_to have_content('View all handover cases')
        end
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
        expect(response.body).to have_content('Make allocations')
        expect(response.body).to have_content('Add missing details')
        expect(response.body).to have_content('View all POMs')
        expect(response.body).to have_text('View all handover cases')
      end

      describe 'Make allocations tab' do
        context 'when the count is more than 0' do
          # create offenders with case_information so that they display as un-allocated
          before do
            offenders.each do |offender|
              create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
            end
          end

          it 'displays the number of cases that need to be allocated' do
            get :index, params: { prison_id: prison }
            expect(assigns(:unallocated_cases_count)).to eq 3
          end

          context 'with render views' do
            render_views
            it 'displays the number of cases that need to be allocated' do
              get :index, params: { prison_id: prison }
              expect(response.body).to include 'You have 3 cases to allocate.'
            end
          end
        end

        context 'when the count is 0' do
          it 'displays the number of cases that need to be allocated' do
            get :index, params: { prison_id: prison }
            expect(assigns(:unallocated_cases_count)).to eq 0
          end

          context 'with render views' do
            render_views
            it 'displays the number of cases that need to be allocated' do
              get :index, params: { prison_id: prison }
              expect(response.body).to include 'You don’t have any cases to allocate currently.'
            end
          end
        end

        context 'when the count is 1' do
          let(:offenders) { build_list(:nomis_offender, 1) }

          before do
            offenders.each do |offender|
              create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
            end
          end

          it 'displays the number of cases that need to be allocated' do
            get :index, params: { prison_id: prison }
            expect(assigns(:unallocated_cases_count)).to eq 1
          end

          context 'with render views' do
            render_views
            it 'displays the number of cases that need to be allocated' do
              get :index, params: { prison_id: prison }
              expect(response.body).to include 'You have 1 case to allocate.'
            end
          end
        end
      end

      describe 'Add missing details tab' do
        context 'when the count is more than 1' do
          # create offenders with no case_information so that they display as having missing details

          it 'displays the number of cases that have missing details' do
            get :index, params: { prison_id: prison }
            expect(assigns(:missing_details_cases_count)).to eq 3
          end

          context 'with render views' do
            render_views
            it 'displays the number of cases that having missing details' do
              get :index, params: { prison_id: prison }
              expect(response.body).to include 'Missing details need to be added to 3 cases before they can be allocated to POMs.'
            end
          end
        end

        context 'when the count is 0' do
          # creates no offenders
          let(:offenders) { build_list(:nomis_offender, 0) }

          it 'displays the number of cases that have missing details' do
            get :index, params: { prison_id: prison }
            expect(assigns(:missing_details_cases_count)).to eq 0
          end

          context 'with render views' do
            render_views
            it 'displays the number of cases that having missing details' do
              get :index, params: { prison_id: prison }
              expect(response.body).to include 'No cases are missing information right now.'
            end
          end
        end

        context 'when the count is 1' do
          context 'when the count is 1' do
            # creates no offenders
            let(:offenders) { build_list(:nomis_offender, 1) }

            it 'displays the number of cases that have missing details' do
              get :index, params: { prison_id: prison }
              expect(assigns(:missing_details_cases_count)).to eq 1
            end

            context 'with render views' do
              render_views
              it 'displays the number of cases that having missing details' do
                get :index, params: { prison_id: prison }
                expect(response.body).to include 'Missing details need to be added to 1 case before it can be allocated to a POM.'
              end
            end
          end
        end
      end
    end
  end
end
