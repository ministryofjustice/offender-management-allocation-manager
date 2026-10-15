require "rails_helper"

describe CaseHistory do
  describe '#reviewed_recommended_pom_type' do
    it 'keeps each review recommendation when subsequent reviews or allocations change it' do
      allocation = create(:allocation_history, prison: create(:prison).code, recommended_pom_type: 'prison')
      allocation.update!(primary_pom_reviewed_at: 2.days.ago, reviewed_recommended_pom_type: 'probation')
      allocation.update!(primary_pom_reviewed_at: 1.day.ago, reviewed_recommended_pom_type: 'prison')
      allocation.update!(primary_pom_reviewed_at: nil, reviewed_recommended_pom_type: nil)

      history = AllocationService.history(allocation)

      expect(history.map(&:reviewed_recommended_pom_type)).to eq([nil, 'probation', 'prison', nil])
      expect(history[1..2].map(&:to_partial_path)).to eq(
        ['case_history/allocation/retain_primary_pom', 'case_history/allocation/retain_primary_pom']
      )
    end
  end

  describe '#created_by_name' do
    context 'when the allocation was retained' do
      let(:allocation) { AllocationHistory.new(event_trigger: 'user', created_by_name: 'Original Allocator') }
      let(:version) do
        PaperTrail::Version.new(
          event: 'update', whodunnit: 'homd',
          object_changes: YAML.dump('primary_pom_reviewed_at' => [nil, Time.current.iso8601])
        )
      end
      let(:case_history) { described_class.new(nil, allocation, version) }

      it 'uses the reviewer name from PaperTrail rather than the original allocator' do
        version.user_first_name = 'Jane'
        version.user_last_name = 'Smith'

        expect(case_history.created_by_name).to eq('Jane Smith')
      end

      it 'falls back to the reviewer username when their name is unavailable' do
        expect(case_history.created_by_name).to eq('homd')
      end
    end

    context 'when the version has a name and note from the system admin' do
      it 'displays System Admin (the admin name)' do
        allocation = AllocationHistory.new
        version = PaperTrail::Version.new(whodunnit: "Test Admin", system_admin_note: "For the following reasons")
        case_history = described_class.new(nil, allocation, version)
        expect(case_history.created_by_name).to eq("System Admin (Test Admin)")
      end
    end

    context 'when the event trigger is user' do
      it 'displays the name from the allocation' do
        allocation = AllocationHistory.new(event_trigger: "user", created_by_name: "End User")
        version = PaperTrail::Version.new
        case_history = described_class.new(nil, allocation, version)
        expect(case_history.created_by_name).to eq("End User")
      end
    end

    it "is nil" do
      allocation = AllocationHistory.new(created_by_name: "End User")
      version = PaperTrail::Version.new
      case_history = described_class.new(nil, allocation, version)
      expect(case_history.created_by_name).to be_nil
    end
  end

  describe '#to_partial_path' do
    it 'uses the retention partial when the review timestamp is recorded' do
      allocation = AllocationHistory.new(event: :allocate_primary_pom)
      version = PaperTrail::Version.new(event: 'update', object_changes: YAML.dump('primary_pom_reviewed_at' => [nil, Time.current.iso8601]))

      expect(described_class.new(nil, allocation, version).to_partial_path)
        .to eq('case_history/allocation/retain_primary_pom')
    end

    it 'uses the coworking partial when an existing review timestamp has not changed' do
      allocation = AllocationHistory.new(event: :allocate_secondary_pom, primary_pom_reviewed_at: 1.day.ago)
      version = PaperTrail::Version.new(event: 'update', object_changes: YAML.dump('secondary_pom_nomis_id' => [nil, 987_654]))

      expect(described_class.new(nil, allocation, version).to_partial_path)
        .to eq('case_history/allocation/allocate_secondary_pom')
    end

    it 'uses the reallocation partial when the review timestamp is cleared' do
      allocation = AllocationHistory.new(event: :reallocate_primary_pom)
      previous_allocation = AllocationHistory.new
      version = PaperTrail::Version.new(event: 'update', object_changes: YAML.dump('primary_pom_reviewed_at' => [1.day.ago.iso8601, nil]))

      expect(described_class.new(previous_allocation, allocation, version).to_partial_path)
        .to eq('case_history/allocation/reallocate_primary_pom')
    end
  end
end
