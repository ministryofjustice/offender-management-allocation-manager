require 'rails_helper'

RSpec.describe SearchController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:nomis_staff_id) { 485_926 }

  let(:poms) {
    [
      build(:pom,
            firstName: 'Alice',
            lastName: 'Ward',
            position: RecommendationService::PRISON_POM,
            staffId: nomis_staff_id
      )
    ]
  }

  before do
    stub_poms(prison, poms)
    stub_signed_in_pom(prison, nomis_staff_id)
  end

  context 'when user is a POM ' do
    before do
      stub_signed_in_pom(prison, nomis_staff_id)
    end

    it 'user is redirected to caseload' do
      get :search, params: { prison_id: prison, q: 'Cal' }
      expect(response).to redirect_to(prison_staff_caseload_index_path(prison, nomis_staff_id, q: 'Cal'))
    end
  end

  context 'when user is an SPO ' do
    before do
      stub_sso_data(prison)
    end

    it 'can search' do
      offenders = build_list(:nomis_offender, 1)
      stub_offenders_for_prison(prison, offenders)

      get :search, params: { prison_id: prison, q: 'Cal' }
      expect(response.status).to eq(200)
      expect(response).to be_successful

      expect(assigns(:q)).to eq('Cal')
      expect(assigns(:offenders).size).to eq(0)
    end

    context "with 3 offenders", :allocation do
      let(:offenders) { build_list(:nomis_offender, 3, lastName: 'Bloggs', firstName: 'Alice') }
      let(:updated_offenders) { assigns(:offenders) }
      let(:alloc_offender) { updated_offenders.detect { |o| o.offender_no == offenders.first.fetch(:offenderNo) } }

      before do
        stub_offenders_for_prison(prison, offenders)
        PomDetail.create!(nomis_staff_id: nomis_staff_id, working_pattern: 1.0, status: 'active')

        create(:allocation,
               nomis_offender_id: offenders.first.fetch(:offenderNo),
               primary_pom_allocated_at: allocated_date,
               primary_pom_nomis_id: nomis_staff_id)
      end

      context "with a date" do
        let(:allocated_date) { DateTime.now.utc }

        it 'gets the POM names for allocated offenders' do
          get :search, params: { prison_id: prison, q: 'Blog' }

          expect(updated_offenders).to be_kind_of(Array)
          expect(updated_offenders.count).to eq(offenders.count)
          expect(alloc_offender).to be_kind_of(HmppsApi::OffenderSummary)
          expect(alloc_offender.allocated_pom_name).to eq('Ward, Alice')
          expect(alloc_offender.allocation_date).to be_kind_of(Date)
        end

        it 'can find all the Alices' do
          get :search, params: { prison_id: prison, q: 'Alice' }

          expect(updated_offenders.count).to eq(offenders.count)
        end
      end

      context "when 'primary_pom_allocated_at' date is nil" do
        let(:allocated_date) { DateTime.now.utc }

        it "uses 'updated_at' date when 'primary_pom_allocated_at' date is nil" do
          get :search, params: { prison_id: prison, q: 'Blog' }

          expect(alloc_offender.allocated_pom_name).to eq('Ward, Alice')
          expect(alloc_offender.allocation_date).to be_kind_of(Date)
        end
      end
    end
  end
end
