require 'rails_helper'

RSpec.describe TasksController, :allocation, type: :controller do
  let(:prison) { build(:prison).code }
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

  before do
    stub_poms(prison, pom)
    stub_signed_in_pom(prison, staff_id)

    offenders = [build(:nomis_offender, :indeterminate, offenderNo: 'G7514GW', firstName: "Alice", lastName: "Aliceson"),
                 build(:nomis_offender, offenderNo: 'G1234VV', firstName: "Bob", lastName: "Bibby"),
                 build(:nomis_offender, offenderNo: 'G1234AB', firstName: "Carole", lastName: "Caroleson"),
                 build(:nomis_offender, offenderNo: 'G1234GG', firstName: "David", lastName: "Davidson")
    ]

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

  context 'when showing parole review date pom tasks' do
    let(:offender_no) { 'G7514GW' }

    before do
      # Allocate all of the offenders to this POM
      # Make sure that we don't generate missing nDelius data by mistake
      create(:case_information, nomis_offender_id: offender_no, tier: 'A')
      create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, nomis_offender_id: 'G1234VV', tier: 'A', mappa_level: 1)
      create(:allocation, nomis_offender_id: 'G1234VV', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, nomis_offender_id: 'G1234AB', tier: 'A', mappa_level: 1)
      create(:allocation, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', mappa_level: 1)
      create(:allocation, nomis_offender_id: 'G1234GG', primary_pom_nomis_id: staff_id, prison: prison)
    end

    it 'can show offenders needing parole review date updates' do
      stub_offender(build(:nomis_offender, :indeterminate, offenderNo: offender_no))

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)

      # We expect only one of these to have a parole review date task
      expect(pomtasks.first.offender_number).to eq(offender_no)
      expect(pomtasks.first.action_label).to eq('Parole review date')
    end
  end

  context 'when showing ndelius update pom tasks' do
    let(:test_strategy) { Flipflop::FeatureSet.current.test! }
    let(:offender_no) { 'G1234VV' }

    before do
      test_strategy.switch!(:auto_delius_import, true)

      stub_offender(build(:nomis_offender, offenderNo: offender_no))

      # Ensure only one of our offenders has missing data and that G7514GW (indeterminate) has a PRD
      create(:case_information, nomis_offender_id: offender_no, tier: 'A', manual_entry: true)
      create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information,  nomis_offender_id: 'G1234AB', tier: 'A', manual_entry: false)
      create(:allocation, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', manual_entry: false)
      create(:allocation, nomis_offender_id: 'G1234GG', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information,  nomis_offender_id: 'G7514GW', tier: 'A', manual_entry: false, parole_review_date: next_week)
      create(:allocation, nomis_offender_id: 'G7514GW', primary_pom_nomis_id: staff_id, prison: prison)
    end

    after do
      test_strategy.switch!(:auto_delius_import, false)
    end

    it 'can show offenders needing nDelius updates' do
      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)
      expect(pomtasks.count).to eq(1)
      expect(pomtasks.first.offender_number).to eq(offender_no)
      expect(pomtasks.first.action_label).to eq('nDelius case matching')
    end
  end

  context 'when showing early allocation decisions required' do
    let(:offender_nos) { %w[G1234AB G1234GG G7514GW G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    it 'can show offenders needing early allocation decision updates' do
      offender_nos.each do |offender_no|
        create(:case_information, nomis_offender_id: offender_no, tier: 'A', mappa_level: 1, parole_review_date: next_week)
        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id, prison: prison)
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
      create(:case_information, nomis_offender_id: 'G1234AB', tier: 'A', mappa_level: 1, parole_review_date: next_week)
      create(:allocation, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, nomis_offender_id: 'G1234GG', tier: 'A', mappa_level: 1, parole_review_date: next_week)
      create(:allocation, nomis_offender_id: 'G1234GG', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, nomis_offender_id: 'G7514GW', tier: 'A', mappa_level: 1)
      create(:allocation, nomis_offender_id: 'G7514GW', primary_pom_nomis_id: staff_id, prison: prison)
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
