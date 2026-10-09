require 'rails_helper'

RSpec.describe SignificantChanges do
  let(:nomis_offender_id) { 'A1234BC' }
  let(:allocated_at) { Time.zone.local(2026, 9, 1, 10) }
  let(:allocation) do
    build(:allocation_history, nomis_offender_id:, primary_pom_allocated_at: allocated_at, primary_pom_nomis_id: 485_926)
  end
  let(:allocated_pom) { instance_double(PomWrapper, staff_id: 485_926, position: RecommendationService::PRISON_POM) }
  let(:poms) { -> { [allocated_pom] } }
  let(:offender) do
    instance_double(MpcOffender, offender_no: nomis_offender_id, full_name: 'Smith, John',
                                 recommended_pom_type: RecommendationService::PROBATION_POM)
  end

  # Recent enough that the allocation is within the lookback period
  let(:today) { Time.zone.local(2026, 9, 10, 12) }

  before { travel_to(today) }

  def version(item_type, changes, created_at)
    PaperTrail::Version.new(item_type:, event: 'update', nomis_offender_id:, created_at:,
                            object_changes: YAML.dump(changes))
  end

  def case_info_version(changes, created_at) = version('CaseInformation', changes, created_at)

  def create_version(item_type, changes, created_at, nomis_offender_id: self.nomis_offender_id, event: 'update')
    PaperTrail::Version.create!(item_type:, item_id: 1, event:, nomis_offender_id:, created_at:,
                                object_changes: YAML.dump(changes))
  end

  def wrapper(*versions) = described_class.new(offender, allocation, versions, poms:)

  it 'runs every detector' do
    expect(
      described_class::DETECTORS
    ).to eq(
      [
        described_class::TierDetector,
        described_class::RoshDetector,
        described_class::HandoverDetector,
      ]
    )
  end

  describe '#changes' do
    subject(:review) do
      wrapper(case_info_version({ 'rosh_level' => %w[MEDIUM HIGH] }, allocated_at + 5.days),
              case_info_version({ 'tier' => %w[B A] }, allocated_at + 2.days))
    end

    it 'lists a change for each detector that finds one' do
      expect(review.changes.map(&:type)).to eq(%i[tier rosh])
      expect(review.labels).to eq(%w[Tier ROSH])
      expect(review).to be_any
    end

    it 'counts working days since the earliest change' do
      # Thursday 3 September to Thursday 10 September
      expect(review.working_days_since_earliest_change).to eq(5)
    end

    it 'has no changes or working days when nothing has changed' do
      expect(wrapper).not_to be_any
      expect(wrapper.working_days_since_earliest_change).to be_nil
    end

    it 'ignores changes made before the allocation' do
      expect(wrapper(case_info_version({ 'tier' => %w[B A] }, allocated_at - 1.day))).not_to be_any
    end
  end

  describe '#allocated_pom_position' do
    it 'looks up the position of the allocated primary POM' do
      expect(wrapper.allocated_pom_position).to eq(RecommendationService::PRISON_POM)
    end

    describe 'review boundary' do
      let(:reviewed_at) { allocated_at + 3.days }

      before { allocation.primary_pom_reviewed_at = reviewed_at }

      it 'ignores reviewed tier, ROSH and handover changes' do
        review = wrapper(
          case_info_version({ 'tier' => %w[B A], 'rosh_level' => %w[LOW HIGH] }, reviewed_at - 1.day),
          version('CalculatedHandoverDate', { 'handover_date' => [Date.new(2026, 9, 10), Date.new(2027, 3, 1)] }, reviewed_at - 1.day)
        )

        expect(review).not_to be_any
        expect(allocation.primary_pom_allocated_at).to eq(allocated_at)
      end

      it 'detects subsequent changes against the values after the review' do
        review = wrapper(
          case_info_version({ 'tier' => %w[B A] }, reviewed_at - 1.day),
          case_info_version({ 'tier' => %w[A B] }, reviewed_at + 1.day),
          case_info_version({ 'rosh_level' => %w[LOW HIGH] }, reviewed_at + 1.day),
          version('CalculatedHandoverDate', { 'handover_date' => [Date.new(2026, 9, 10), Date.new(2027, 3, 1)] }, reviewed_at + 1.day)
        )

        expect(review.changes.map(&:type)).to eq(%i[tier rosh handover])
        expect(review.changes.first.from_value).to eq('A')
        expect(review.changes.first.to_value).to eq('B')
      end

      it 'does not load versions before the review' do
        create_version('CaseInformation', { 'tier' => %w[B A] }, reviewed_at - 1.day)
        later_version = create_version('CaseInformation', { 'tier' => %w[A B] }, reviewed_at + 1.day)

        expect(described_class.load_versions([allocation])).to eq([later_version])
      end

      it 'uses a subsequent allocation date rather than an older review date' do
        allocation.primary_pom_allocated_at = reviewed_at + 2.days

        expect(described_class.start_date_for(allocation)).to eq(allocation.primary_pom_allocated_at)
      end

      it 'still applies the lookback period when the review is older' do
        travel_to(reviewed_at + described_class::LOOKBACK_PERIOD + 1.day)

        expect(described_class.start_date_for(allocation)).to eq(described_class::LOOKBACK_PERIOD.ago.beginning_of_day)
      end
    end

    it 'is nil when the allocated primary POM is not in the list' do
      allow(allocated_pom).to receive(:staff_id).and_return(1)

      expect(wrapper.allocated_pom_position).to be_nil
    end
  end

  describe '#recommendation_differs_from_allocation?' do
    it 'returns true when MPC recommends a different POM type from the allocated POM' do
      allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)

      expect(wrapper.recommendation_differs_from_allocation?).to be(true)
    end

    it 'returns false when the allocated POM matches the recommendation' do
      allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)

      expect(wrapper.recommendation_differs_from_allocation?).to be(false)
    end

    it 'returns false when there is no recommendation' do
      allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::NO_RECOMMENDATION)

      expect(wrapper.recommendation_differs_from_allocation?).to be(false)
    end

    it 'returns false when the allocated POM type is unknown' do
      allow(allocated_pom).to receive(:position).and_return(nil)

      expect(wrapper.recommendation_differs_from_allocation?).to be(false)
    end
  end

  describe 'lookback period' do
    # The lookback period starts at the beginning of 6 September
    let(:today) { allocated_at + 5.days + described_class::LOOKBACK_PERIOD }

    it 'ignores changes before the lookback period, even if after the allocation' do
      expect(wrapper(case_info_version({ 'tier' => %w[B A] }, allocated_at + 1.day))).not_to be_any
    end

    it 'compares against the value at the start of the lookback period' do
      review = wrapper(case_info_version({ 'tier' => %w[B A] }, allocated_at + 1.day),
                       case_info_version({ 'tier' => %w[A C] }, allocated_at + 6.days))

      expect(review.changes.map { [it.from_value, it.to_value] }).to eq([%w[A C]])
    end

    it 'does not load versions from before the lookback period' do
      create_version('CaseInformation', { 'tier' => %w[B A] }, allocated_at + 1.day)

      expect(described_class.load_versions([allocation])).to be_empty
    end
  end

  describe '.load_versions' do
    it 'only loads update versions for the item types the detectors track' do
      create_version('CaseInformation', {}, allocated_at + 1.day)
      create_version('CalculatedHandoverDate', {}, allocated_at + 1.day)
      create_version('AllocationHistory', {}, allocated_at + 1.day)
      create_version('CaseInformation', {}, allocated_at + 1.day, event: 'destroy')

      expect(described_class.load_versions([allocation]).map(&:item_type))
        .to eq(%w[CaseInformation CalculatedHandoverDate])
    end
  end

  describe '.for' do
    let(:other_offender) do
      instance_double(MpcOffender, offender_no: 'Z9999ZZ', recommended_pom_type: RecommendationService::PRISON_POM)
    end

    before { create_version('CaseInformation', { 'tier' => %w[B A] }, allocated_at + 1.day) }

    it 'builds a wrapper for each allocated offender with their versions' do
      result = described_class.for([offender, other_offender], [allocation], poms:)

      expect(result.map { [it.offender_no, it.labels] }).to eq([[nomis_offender_id, %w[Tier]]])
    end

    it 'ignores allocations without a primary POM allocation date' do
      allocation_without_date = build(:allocation_history, nomis_offender_id: 'Z9999ZZ', primary_pom_allocated_at: nil)

      result = described_class.for([offender, other_offender], [allocation, allocation_without_date], poms:)

      expect(result.map(&:offender_no)).to eq([nomis_offender_id])
    end

    it "only uses changes since each offender's own allocation" do
      other_allocation = build(:allocation_history, nomis_offender_id: 'Z9999ZZ', primary_pom_allocated_at: allocated_at - 1.year,
                                                    primary_pom_nomis_id: 485_927)
      other_pom = instance_double(PomWrapper, staff_id: 485_927, position: RecommendationService::PROBATION_POM)
      # Before this offender's allocation, but after the other offender's
      create_version('CaseInformation', { 'rosh_level' => %w[LOW HIGH] }, allocated_at - 1.day)
      create_version('CaseInformation', { 'rosh_level' => %w[LOW HIGH] }, allocated_at - 1.day, nomis_offender_id: 'Z9999ZZ')

      result = described_class.for([offender, other_offender], [allocation, other_allocation], poms: -> { [allocated_pom, other_pom] })

      expect(result.map { [it.offender_no, it.labels] }).to eq([[nomis_offender_id, %w[Tier]], ['Z9999ZZ', %w[ROSH]]])
    end

    it 'loads the POMs to compare a significant change with the recommendation' do
      poms = instance_double(Proc, call: [allocated_pom])
      described_class.for([offender], [allocation], poms:).each(&:changes)

      expect(poms).to have_received(:call)
    end

    it "only uses changes since each offender's own review" do
      allocation.primary_pom_reviewed_at = allocated_at + 2.days
      other_allocation = build(:allocation_history, nomis_offender_id: 'Z9999ZZ', primary_pom_allocated_at: allocated_at,
                                                    primary_pom_nomis_id: 485_927)
      other_pom = instance_double(PomWrapper, staff_id: 485_927, position: RecommendationService::PROBATION_POM)
      create_version('CaseInformation', { 'tier' => %w[B A] }, allocated_at + 1.day, nomis_offender_id: 'Z9999ZZ')

      result = described_class.for([offender, other_offender], [allocation, other_allocation], poms: -> { [allocated_pom, other_pom] })

      expect(result.map { [it.offender_no, it.labels] }).to eq([[nomis_offender_id, []], ['Z9999ZZ', %w[Tier]]])
    end

    it 'uses the allocated POM position when a detector needs it' do
      create_version(
        'CalculatedHandoverDate',
        { 'handover_date' => [Date.new(2026, 9, 1), Date.new(2027, 3, 1)] },
        allocated_at + 1.day
      )
      allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)

      result = described_class.for([offender], [allocation], poms:)

      expect(result.first.labels).to eq(['Tier', 'Handover date'])
    end
  end
end
