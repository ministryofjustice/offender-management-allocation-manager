require 'rails_helper'

describe Ndelius::FakeRecord do
  describe 'Generating a fake record' do
    let(:subject) { described_class }

    context 'when the Nomis id ends with A, B, C, D' do
      it 'returns a FakeRecord with tier A' do
        %w[A1234BA A1234BB A1234BC A1234BD].each do |nomis_id|
          record = subject.generate(nomis_id)

          expect(record.tier).to eq('A')
          expect(record.nomis_id).to eq(nomis_id)
          expect(record.case_allocation).to eq('NPS')
        end
      end
    end

    context 'when the Nomis id ends with E, F, G, H' do
      it 'returns a FakeRecord with tier B' do
        %w[A1234BE A1234BF A1234BG A1234BH].each do |nomis_id|
          record = subject.generate(nomis_id)

          expect(record.tier).to eq('B')
          expect(record.nomis_id).to eq(nomis_id)
          expect(record.case_allocation).to eq('NPS')
        end
      end
    end

    context 'when the Nomis id ends with I, J, K, L' do
      it 'returns a FakeRecord with tier C' do
        %w[A1234BI A1234BJ A1234BK A1234BL].each do |nomis_id|
          record = subject.generate(nomis_id)

          expect(record.tier).to eq('C')
          expect(record.nomis_id).to eq(nomis_id)
          expect(record.case_allocation).to eq('CRC')
        end
      end
    end

    context 'when the Nomis id ends with M, N, O, P' do
      it 'returns a FakeRecord with tier D' do
        %w[A1234BM A1234BN A1234BO A1234BP].each do |nomis_id|
          record = subject.generate(nomis_id)

          expect(record.tier).to eq('D')
          expect(record.nomis_id).to eq(nomis_id)
          expect(record.case_allocation).to eq('CRC')
        end
      end
    end

    context 'when the Nomis id ends with Q, R, S, T' do
      it 'raises a NoTier exception' do
        %w[A1234BQ A1234BR A1234BS A1234BT].each do |nomis_id|
          expect { subject.generate(nomis_id) }.to raise_error(Ndelius::NoTierException)
        end
      end
    end

    context 'when the Nomis id ends with U, V, W, X' do
      it 'raises a MultipleRecordException' do
        %w[A1234BU A1234BV A1234BW A1234BX].each do |nomis_id|
          expect { subject.generate(nomis_id) }.to raise_error(Ndelius::MultipleRecordException)
        end
      end
    end

    context 'when the Nomis id ends with Y, Z' do
      it 'returns a NoRecordException' do
        %w[A1234BY A1234BZ].each do |nomis_id|
          expect { subject.generate(nomis_id) }.to raise_error(Ndelius::NoRecordException)
        end
      end
    end
  end
end
