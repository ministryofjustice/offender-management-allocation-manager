require 'rails_helper'

RSpec.describe TasksController, :allocation, type: :controller do
  let(:prison) { create(:prison).code }
  let(:staff_id) { 123 }
  let(:pom) {
    [
      build(:pom,
            staffId: staff_id,
            position: RecommendationService::PRISON_POM
      )
    ]
  }

  let(:next_week) { Time.zone.today + 7.days }
  let(:tariff_end_date) { Time.zone.today - 3.days }
  let(:offenders) {
    [build(:nomis_offender, prisonerNumber: 'G7514GW', firstName: "Alice", lastName: "Aliceson",
           sentence: attributes_for(:sentence_detail, :indeterminate, tariffDate: tariff_end_date)),
     build(:nomis_offender, prisonerNumber: 'G1234VV', firstName: "Bob", lastName: "Bibby"),
     build(:nomis_offender, prisonerNumber: 'G1234AB', firstName: "Carole", lastName: "Caroleson"),
     build(:nomis_offender, prisonerNumber: 'G1234GG', firstName: "David", lastName: "Davidson")
    ]
  }

  before do
    stub_poms(prison, pom)
    stub_signed_in_pom(prison, staff_id)
    stub_offenders_for_prison(prison, offenders)
  end

  context 'when an SPO' do
    before do
      stub_sso_data(prison)
    end

    it 'return a 401' do
      get :index, params: { prison_id: prison }

      expect(response).to redirect_to '/401'
    end
  end

  describe 'showing parole review date pom tasks' do
    let(:offender_no) { 'G7514GW' }
    let(:pomtasks) { assigns(:pomtasks) }

    before do
      # Allocate all of the offenders to this POM
      # Make sure that we don't generate missing nDelius data by mistake
      offenders.each do |offender|
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)), tier: 'A')
        create(:allocation_history, nomis_offender_id: offender.fetch(:prisonerNumber), primary_pom_nomis_id: staff_id, prison: prison)
      end
      get :index, params: { prison_id: prison }

      expect(response).to be_successful
    end

    context 'with a TED in the past' do
      let(:tariff_end_date) { Time.zone.today - 3.days }

      it 'can show offenders needing parole review date updates' do
        # We expect only one of these to have a parole review date task
        expect(pomtasks).to eq([PomTaskPresenter.new(offender_number: offender_no,
                                                     action_label: 'Parole review date',
                                                     offender_name: 'Aliceson, Alice',
                                                     long_label: 'Parole review date must be updated so handover dates can be calculated.')])
      end
    end

    context 'with a TED in the future' do
      let(:tariff_end_date) { Time.zone.today + 3.days }

      it 'does not show PRD task' do
        expect(pomtasks).to eq([])
      end
    end
  end

  context 'when showing early allocation decisions required' do
    let(:offender_nos) { %w[G1234AB G1234GG G7514GW G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    it 'can show offenders needing early allocation decision updates' do
      offender_nos.each do |offender_no|
        create(:case_information, tier: 'A', mappa_level: 1,
               offender: build(:offender, nomis_offender_id: offender_no, parole_record: build(:parole_record, parole_review_date: next_week)))
        create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id, prison: prison)
      end

      create(:early_allocation, :discretionary, nomis_offender_id: test_offender_no)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.map { |pt| { num: pt.offender_number, label: pt.action_label } }).to eq([{ num: test_offender_no, label: 'Early allocation decision' }])
    end
  end

  context 'when showing tasks' do
    let(:offender_nos) { %w[G1234AB G1234GG G7514GW G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    before do
      # One offender (G1234VV) should have missing case info and one should have no PRD
      create(:case_information, tier: 'A', mappa_level: 1,
             offender: build(:offender, nomis_offender_id: 'G1234AB', parole_record: build(:parole_record, parole_review_date: next_week)))
      create(:allocation_history, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, tier: 'A', mappa_level: 1,
             offender: build(:offender, nomis_offender_id: 'G1234GG', parole_record: build(:parole_record, parole_review_date: next_week)))
      create(:allocation_history, nomis_offender_id: 'G1234GG', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, offender: build(:offender, nomis_offender_id: 'G7514GW'), tier: 'A', mappa_level: 1)
      create(:allocation_history, nomis_offender_id: 'G7514GW', primary_pom_nomis_id: staff_id, prison: prison)
    end

    it 'can show multiple types at once' do
      # One offender should have a pending early allocation
      create(:early_allocation, :discretionary, nomis_offender_id: test_offender_no)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(2)
    end

    it 'can sort the results' do
      # Two offenders should have a pending early allocation
      create(:early_allocation, :discretionary, nomis_offender_id: 'G1234AB')
      create(:early_allocation, :discretionary, nomis_offender_id: 'G1234GG')
      # This 'task' doesn't show up as it was created before the referral window of <18 months before release
      create(:early_allocation, :discretionary, created_within_referral_window: false, nomis_offender_id: 'G7514GW')

      get :index, params: { prison_id: prison, sort: 'offender_name asc' }
      expect(response).to be_successful
      pomtasks = assigns(:pomtasks)
      expect(pomtasks.map(&:offender_name)).to eq(['Aliceson, Alice', "Caroleson, Carole", 'Davidson, David'])

      get :index, params: { prison_id: prison, sort: 'offender_name desc' }
      expect(response).to be_successful
      pomtasks = assigns(:pomtasks)
      expect(pomtasks.map(&:offender_name)).to eq(['Davidson, David', "Caroleson, Carole", 'Aliceson, Alice'])
    end
  end
end
