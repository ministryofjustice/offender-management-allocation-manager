require "rails_helper"

describe CaseHistory do
  describe '#created_by_name' do
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
      expect(case_history.created_by_name).to be(nil)
    end
  end
end
