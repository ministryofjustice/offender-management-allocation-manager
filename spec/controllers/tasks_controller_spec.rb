require 'rails_helper'

RSpec.describe TasksController, :allocation, type: :controller do
  let(:prison) { create(:prison).code }
  let(:staff_id) { 123 }
  let(:pom) do
    [
      build(:pom,
            staffId: staff_id,
            position: RecommendationService::PRISON_POM
           )
    ]
  end

  let(:next_week) { Time.zone.today + 7.days }
  let(:tariff_end_date) { Time.zone.today - 3.days }
  let(:offenders) do
    [
      build(:nomis_offender, prisonerNumber: 'G1234VV', firstName: "Bob", lastName: "Bibby"),
      build(:nomis_offender, prisonerNumber: 'G1234AB', firstName: "Carole", lastName: "Caroleson"),
      build(:nomis_offender, prisonerNumber: 'G1234GG', firstName: "David", lastName: "Davidson")
    ]
  end

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

  context 'when showing early allocation decisions required' do
    let(:offender_nos) { %w[G1234AB G1234GG G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    it 'can show offenders needing early allocation decision updates' do
      offender_nos.each do |offender_no|
        create(:case_information, tier: 'A', mappa_level: 1,
                                  offender: build(:offender, nomis_offender_id: offender_no, parole_records: [build(:parole_record, hearing_outcome_received: Time.zone.today)]))
        create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id, prison: prison)
      end

      create(:early_allocation, :discretionary, nomis_offender_id: test_offender_no)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)

      expect(pomtasks.map do |pt|
        task_presenter = PomTaskPresenter.new(pt)
        { num: task_presenter.offender_number, label: task_presenter.action_label }
      end).to eq([{ num: test_offender_no, label: 'Early allocation decision' }])
    end
  end

  context 'when showing missing hearing outcome confirmed date' do
    let(:offender_nos) { %w[G1234AB G1234GG G1234VV] }
    let(:test_offender_no) { 'G1234AB' }

    it 'can show offenders needing a hearing outcome confirmed date' do
      create(:case_information, tier: 'A', mappa_level: 1,
                                offender: build(:offender, nomis_offender_id: 'G1234AB', parole_records: [build(:parole_record)]))
      create(:allocation_history, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, tier: 'A', mappa_level: 1,
                                offender: build(:offender, nomis_offender_id: 'G1234GG', parole_records: [build(:parole_record, hearing_outcome_received: Time.zone.today)]))
      create(:allocation_history, nomis_offender_id: 'G1234GG', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, tier: 'A', mappa_level: 1,
                                offender: build(:offender, nomis_offender_id: 'G1234VV', parole_records: [build(:parole_record, hearing_outcome_received: Time.zone.today)]))
      create(:allocation_history, nomis_offender_id: 'G1234VV', primary_pom_nomis_id: staff_id, prison: prison)

      get :index, params: { prison_id: prison }

      expect(response).to be_successful

      pomtasks = assigns(:pomtasks)

      expect(pomtasks.map do |pt|
        task_presenter = PomTaskPresenter.new(pt)
        { num: task_presenter.offender_number, label: task_presenter.action_label }
      end).to eq([{ num: test_offender_no, label: 'Date parole hearing outcome confirmed' }])
    end
  end

  context 'when showing tasks' do
    before do
      create(:case_information, tier: 'A', mappa_level: 1,
                                offender: build(:offender, nomis_offender_id: 'G1234AB', parole_records: [build(:parole_record, hearing_outcome_received: Time.zone.today)]))
      create(:allocation_history, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, tier: 'A', mappa_level: 1,
                                offender: build(:offender, nomis_offender_id: 'G1234GG', parole_records: [build(:parole_record, hearing_outcome_received: Time.zone.today)]))
      create(:allocation_history, nomis_offender_id: 'G1234GG', primary_pom_nomis_id: staff_id, prison: prison)

      create(:case_information, tier: 'A', mappa_level: 1,
                                offender: build(:offender, nomis_offender_id: 'G1234VV', parole_records: [build(:parole_record)]))
      create(:allocation_history, nomis_offender_id: 'G1234VV', primary_pom_nomis_id: staff_id, prison: prison)
    end

    it 'can sort the results' do
      # Two offenders should have a pending early allocation and one should be missing hearing_outcome_recieved
      create(:early_allocation, :discretionary, nomis_offender_id: 'G1234AB')
      create(:early_allocation, :discretionary, nomis_offender_id: 'G1234GG')

      get :index, params: { prison_id: prison, sort: 'offender_name asc' }
      expect(response).to be_successful
      pomtasks = assigns(:pomtasks)
      expect(pomtasks.map(&:offender_name)).to eq(["Bibby, Bob", "Caroleson, Carole", 'Davidson, David'])

      get :index, params: { prison_id: prison, sort: 'offender_name desc' }
      expect(response).to be_successful
      pomtasks = assigns(:pomtasks)
      expect(pomtasks.map(&:offender_name)).to eq(['Davidson, David', "Caroleson, Carole", "Bibby, Bob"])
    end
  end
end
