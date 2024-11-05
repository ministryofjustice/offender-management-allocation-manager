# frozen_string_literal: true

RSpec.describe Prison do
  describe '#active' do
    before do
      create(:allocation_history, prison: p1.code)
      create(:allocation_history, prison: p1.code)
      create(:allocation_history, prison: p2.code)
    end

    let(:p1) { create(:prison) }
    let(:p2) { create(:prison) }

    it 'only lists prisons with allocations' do
      expect(described_class.active.map(&:code)).to match_array [p1, p2].map(&:code)
    end
  end

  describe '#womens?' do
    context 'with a male prison' do
      let(:prison) { create(:prison) }

      it 'is false' do
        expect(prison.womens?).to eq(false)
      end
    end

    context 'with a female prison' do
      let(:prison) { create(:womens_prison) }

      it 'is true' do
        expect(prison.womens?).to eq(true)
      end
    end
  end

  describe '#unfiltered_offenders' do
    subject { described_class.new(code: 'LEI').unfiltered_offenders }

    it "get first page of offenders for a specific prison",
       vcr: { cassette_name: 'prison_api/offender_service_offenders_by_prison_first_page_spec' } do
      offender_array = subject.first(9)
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to eq(9)
    end

    it "get last page of offenders for a specific prison", vcr: { cassette_name: 'prison_api/offender_service_offenders_by_prison_last_page_spec' } do
      offender_array = subject.to_a
      expect(offender_array).to be_kind_of(Array)
      expect(offender_array.length).to be > 800
    end

    context 'when recall flag set' do
      let(:offenders) { build_list(:nomis_offender, 2, sentence: attributes_for(:sentence_detail, recall: true)) }

      before do
        stub_auth_token
        stub_offenders_for_prison('LEI', offenders)
        create(:offender, nomis_offender_id: offenders.first.fetch(:prisonerNumber))
      end

      it 'populates the recall flag' do
        expect(subject.map(&:recalled?)).to eq [true, true]
      end

      it 'creates the missing offender object' do
        expect(Offender.count).to eq(1)
        expect(subject.count).to eq(2)
        expect(Offender.count).to eq(2)
      end
    end

    describe 'Validations' do
      subject do
        described_class.new(prison_type: 'mens_open',
                            code: 'ACI',
                            name: 'HMP Altcourse')
      end

      it "is not valid without a prison_type" do
        subject.prison_type = nil
        expect(subject).to be_invalid
      end

      it "is not valid without a code" do
        subject.code = nil
        expect(subject).to be_invalid
      end

      it 's code must be unique' do
        described_class.create!(prison_type: 'mens_open',
                                code: 'ACI',
                                name: 'HMP Altcourse')

        expect(subject).to be_invalid
      end

      it 's name must be unique' do
        described_class.create!(prison_type: 'mens_open',
                                code: 'AGI',
                                name: 'HMP Altcourse')

        expect(subject).to be_invalid
      end

      it "is valid when all values are present" do
        expect(subject).to be_valid
      end
    end

    describe 'Associations with PomDetail' do
      let!(:prison) { create(:prison) }

      before do
        create_list(:pom_detail, 5, prison: prison)
      end

      it 'has many pom details' do
        expect(described_class.find(prison.code).pom_details.size).to be(5)
      end
    end
  end

  describe '#allocations_for_pom' do
    it 'returns all AllocatedOffenders in this prison for the POM with the given nomis_staff_id' do
      prison = FactoryBot.create :prison
      nomis_staff_id = 'STAFF1'
      expected_allocations = double(:expected_allocations)
      # This crap codebase forces us to stub out methods on the class we're testing - this is awful practice and a "test
      # smell" indicating badly drawn boundaries between components. But refactoring the whole thing is not practical so
      # we are forced to use this bad practice.
      alloc_relation = double :allocation_relation, for_pom: []
      allow(prison).to receive(:allocations).and_return(alloc_relation)
      allow(alloc_relation).to receive(:for_pom).with(nomis_staff_id).and_return(expected_allocations)

      expect(prison.allocations_for_pom(nomis_staff_id)).to eq expected_allocations
    end
  end

  describe '#primary_allocated_offenders' do
    let(:prison) { FactoryBot.create :prison }
    let(:allocation_history) { FactoryBot.create_list :allocation_history, 3, :primary, prison: prison.code }
    let(:mpc_offenders) do
      allocation_history.map do |ah|
        nomis_offender_id = ah.nomis_offender_id
        instance_double MpcOffender, "mpc_offender-#{nomis_offender_id}", offender_no: nomis_offender_id,
                                                                          nomis_offender_id:,
                                                                          inside_omic_policy?: true,
                                                                          case_information: double,
                                                                          released?: false,
                                                                          allocatable?: true
      end
    end
    let(:allocated_offenders) do
      allocation_history.each { |ah| instance_double AllocatedOffender, "allocated_offender-#{ah.nomis_offender_id}" }
    end
    let(:unrelated_allocation_history) { FactoryBot.create_list :allocation_history, 3, :primary }

    before do
      allow(prison).to receive(:unfiltered_offenders).and_return(mpc_offenders)
      mpc_offenders.each { |o| Offender.create! nomis_offender_id: o.offender_no }

      allocation_history.each_with_index do |ah, idx|
        allow(AllocatedOffender).to receive(:new).with(ah.primary_pom_nomis_id, ah, mpc_offenders[idx])
                                                 .and_return(allocated_offenders[idx])
      end
    end

    it 'builds AllocatedOffender objects for each offender allocated to a primary POM in this prison' do
      expect(prison.primary_allocated_offenders).to match_array(allocated_offenders)
    end

    it 'filters out released offenders' do
      allow(mpc_offenders[0]).to receive_messages(released?: true)
      expect(prison.primary_allocated_offenders).not_to include(allocated_offenders[0])
    end
  end
end
