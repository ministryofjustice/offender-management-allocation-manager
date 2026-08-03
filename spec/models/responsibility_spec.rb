require 'rails_helper'

RSpec.describe Responsibility, type: :model do
  let(:offender) { create(:offender) }

  before do
    create(:case_information, offender: offender)
  end

  describe 'responsibility' do
    it { expect(described_class.new(value: Responsibility::PRISON)).to be_pom_responsible }
    it { expect(described_class.new(value: Responsibility::PRISON)).to be_com_supporting }
    it { expect(described_class.new(value: Responsibility::PRISON)).not_to be_com_responsible }
    it { expect(described_class.new(value: Responsibility::PRISON)).not_to be_pom_supporting }
    it { expect(described_class.new(value: Responsibility::PROBATION)).to be_com_responsible }
    it { expect(described_class.new(value: Responsibility::PROBATION)).to be_pom_supporting }
    it { expect(described_class.new(value: Responsibility::PROBATION)).not_to be_pom_responsible }
    it { expect(described_class.new(value: Responsibility::PROBATION)).not_to be_com_supporting }
  end

  describe '.human_reason' do
    it 'returns the shared translated label for a reason key' do
      expect(described_class.human_reason(:less_than_10_months_to_serve)).to eq(
        'The prisoner has less than 10 months less to serve'
      )
    end

    it 'returns an empty string when a locale entry is not present' do
      expect(described_class.human_reason('unknown_reason')).to eq('')
    end
  end

  context 'with other reason' do
    subject { build(:responsibility, offender: offender, reason: :other_reason) }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(reason_text: ["Please provide reason when Other is selected"])
    end
  end

  context 'with default factory' do
    subject { build(:responsibility, offender: offender) }

    it { is_expected.to be_valid }
  end

  context 'with invalid override' do
    subject { build(:responsibility, offender: offender, value: 'wibble') }

    it 'is not valid' do
      expect(subject).not_to be_valid
      expect(subject.errors.messages).to eq(value: ["is not included in the list"])
    end
  end

  context 'with prison override' do
    subject { build(:responsibility, offender: offender, value: 'Prison') }

    it { is_expected.to be_valid }
  end

  describe '#save_audit_event' do
    before do
      PaperTrail.request.whodunnit = 'HOMD_USER'
    end

    after do
      PaperTrail.request.whodunnit = nil
    end

    it 'only includes value and reason in the audit data on create' do
      responsibility = create(:responsibility, offender: offender)

      audit = AuditEvent.order(:created_at).last
      aggregate_failures do
        expect(audit.data['after'].keys).to contain_exactly('value', 'reason')
        expect(audit.data['after']).to eq(
          'value' => responsibility.value,
          'reason' => responsibility.reason
        )
      end
    end

    it 'only includes value and reason in the audit data on destroy' do
      responsibility = create(:responsibility, offender: offender)

      responsibility.destroy!

      audit = AuditEvent.order(:created_at).last
      aggregate_failures do
        expect(audit.data['before'].keys).to contain_exactly('value', 'reason')
        expect(audit.data['before']).to eq(
          'value' => responsibility.value,
          'reason' => responsibility.reason
        )
        expect(audit.data['after']).to eq({})
      end
    end
  end
end
