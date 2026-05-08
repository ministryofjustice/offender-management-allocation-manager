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

  describe 'audit events' do
    let(:audit_payloads) { [] }

    before do
      allow(AuditEvent).to receive(:publish) do |**payload|
        audit_payloads << payload
      end
      PaperTrail.request.whodunnit = 'HOMD_USER'
    end

    after do
      PaperTrail.request.whodunnit = nil
    end

    it 'publishes an audit event when a responsibility override is created' do
      create(:responsibility, offender: offender)

      expect(AuditEvent).to have_received(:publish).once
      expect(audit_payloads.last).to include(
        nomis_offender_id: offender.nomis_offender_id,
        tags: %w[record responsibility override created],
        system_event: false,
        username: 'HOMD_USER',
        data: {
          'value' => Responsibility::PROBATION,
          'reason' => 'less_than_10_months_to_serve',
        }
      )
    end

    it 'publishes an audit event when a responsibility override is removed' do
      responsibility = create(:responsibility, offender: offender)

      responsibility.destroy!

      expect(audit_payloads.last).to include(
        nomis_offender_id: offender.nomis_offender_id,
        tags: %w[record responsibility override removed],
        system_event: false,
        username: 'HOMD_USER',
        data: {
          'value' => Responsibility::PROBATION,
          'reason' => 'less_than_10_months_to_serve',
        }
      )
    end
  end
end
