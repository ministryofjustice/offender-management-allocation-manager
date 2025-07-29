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

    let(:offenders) { build_list(:nomis_offender, 3) }

    before do
      stub_offenders_for_prison('LEI', offenders)
    end

    it "get offenders for a specific prison" do
      offender_array = subject.to_a
      expect(offender_array).to be_a(Array)
      expect(offender_array.length).to eq(3)
    end

    context 'when recall flag set' do
      let(:offenders) { build_list(:nomis_offender, 2, sentence: attributes_for(:sentence_detail, recall: true)) }

      before do
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
                                                                          released?: false
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

  describe '#get_list_of_poms' do
    let(:prison) { create(:prison) }
    let(:pom1) { build(:pom, hoursPerWeek: 18.75) }
    let(:pom2) { build(:pom, hoursPerWeek: 11.25) }
    let(:duplicate_pom1) { build(:pom, staffId: pom1.staff_id) }
    let(:non_pom) { build(:pom, position: 'STAFF') }

    before do
      stub_poms(prison.code, [pom1, pom2, duplicate_pom1, non_pom])
    end

    it 'returns a list of wrapped POMs' do
      result = prison.get_list_of_poms

      expect(result.size).to eq(2)
      expect(result).to all(be_a(PomWrapper))
      expect(result.map(&:staff_id)).to match_array([pom1.staff_id, pom2.staff_id])
    end

    it 'creates POM details for new POMs' do
      expect {
        prison.get_list_of_poms
      }.to change(PomDetail, :count).by(2)
    end

    it 'uses working pattern details pulled from the POM' do
      result = prison.get_list_of_poms

      expect(result.map(&:status)).to all(eq('active'))
      expect(result[0].working_pattern).to eq(0.5)
      expect(result[1].working_pattern).to eq(0.3)
    end

    context 'when fetching a specific POM' do
      before do
        stub_filtered_pom(prison.code, pom1)
      end

      it 'returns only the specified POM' do
        result = prison.get_list_of_poms(staff_id: pom1.staff_id)

        expect(result.size).to eq(1)
        expect(result.first.staff_id).to eq(pom1.staff_id)
      end
    end
  end
end
