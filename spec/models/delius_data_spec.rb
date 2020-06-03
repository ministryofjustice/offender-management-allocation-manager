require 'rails_helper'

RSpec.describe DeliusData, type: :model do
  describe 'tier changes' do
    let!(:delius_data) do
      described_class.create!(
        crn: '1',
        noms_no: 'A1234Z',
        tier: 'A'
      )
    end

    it 'will create a tier change record' do
      expect {
        delius_data.update!(tier: 'B')
      }.to change(TierChange, :count).by(1)
      TierChange.last.tap do |tier_change|
        expect(tier_change.old_tier).to eq('A')
        expect(tier_change.new_tier).to eq('B')
        expect(tier_change.noms_no).to eq('A1234Z')
      end
    end
  end

  describe '#welsh_offender?' do
    context 'when a record is Welsh' do
      subject {
        described_class.new(
          crn: '1',
          noms_no: 'A1234Z',
          ldu_code: 'WPT123'
        )
      }

      it { is_expected.to be_welsh_offender }
    end

    context 'when a record is not Welsh' do
      subject {
        described_class.new(
          crn: '1',
          noms_no: 'A1234Z',
          ldu_code: 'XPT123'
        )
      }

      it { is_expected.not_to be_welsh_offender }
    end
  end

  describe '#service_provider' do
    context 'when provider code starts with C' do
      subject {
        described_class.new(
          crn: '1',
          noms_no: 'A1234Z',
          provider_code: 'C123'
        ).service_provider
      }

      it { is_expected.to eq('CRC') }
    end

    context 'when provider code starts with N' do
      subject {
        described_class.new(
          crn: '1',
          noms_no: 'A1234Z',
          provider_code: 'N123'
        ).service_provider
      }

      it { is_expected.to eq('NPS') }
    end

    context 'when provider code is invalid' do
      subject {
        described_class.new(
          crn: '1',
          noms_no: 'A1234Z',
          provider_code: 'X123'
        ).service_provider
      }

      it { is_expected.to be_nil }
    end
  end
end
