# This file contains shared behaviour which every type of OffenderEvent should implement
# This comes 'for free' so long as the event extends OffenderEvent
# Include it in your spec with:
#   require 'models/events/offender_event_shared'
# and then inside the main describe block:
#   include_context "core OffenderEvent behaviour"

RSpec.shared_examples "an OffenderEvent" do
  describe 'read-only behaviour after creation' do
    before { subject.save! }

    it 'cannot be updated' do
      subject.happened_at = 1.day.ago
      expect { subject.save! }.to raise_error(ActiveRecord::ReadOnlyRecord)
      expect { subject.update_attribute(:nomis_offender_id, 'ABC123') }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'cannot be deleted' do
      expect { subject.destroy }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe 'core validation' do
    subject { described_class.new }

    it { is_expected.to validate_presence_of(:nomis_offender_id) }
    it { is_expected.to validate_presence_of(:happened_at) }
    it { is_expected.to validate_presence_of(:type) }
    it { is_expected.to validate_presence_of(:triggered_by) }

    context 'when triggered by a user' do
      before { subject.triggered_by = :user }

      it { is_expected.to validate_presence_of(:triggered_by_nomis_username) }
    end

    context 'when triggered by the system' do
      before { subject.triggered_by = :system }

      it { is_expected.not_to validate_presence_of(:triggered_by_nomis_username) }
    end
  end
end
