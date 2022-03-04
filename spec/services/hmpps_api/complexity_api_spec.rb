# frozen_string_literal: true

require "rails_helper"

describe HmppsApi::ComplexityApi do
  describe '#get_complexity', vcr: { cassette_name: 'complexity/get_complexity' } do
    scenario 'item present' do
      expect(described_class.get_complexity 'G0276VC').to eq('high')
    end

    scenario 'item absent' do
      expect(described_class.get_complexity 'T0276VC').to eq(nil)
    end
  end

  describe '#save', vcr: { cassette_name: 'complexity/save_complexity' } do
    let(:saved_offender_no) { 'S0005FT' }

    scenario 'happy path' do
      described_class.save saved_offender_no, level: 'high', username: 'SDICKS_GEN', reason: 'Happy Feet'
      expect(described_class.get_complexity saved_offender_no).to eq('high')
    end
  end

  describe '#get_complexities', vcr: { cassette_name: 'complexity/get_complexities' } do
    scenario 'happy path' do
      expect(described_class.get_complexities ['G0276VC', 'T0000FT'])
        .to eq('G0276VC' => 'high', 'T0000FT' => 'high')
    end

    scenario 'with one item missing' do
      expect(described_class.get_complexities ['G0276VC', 'T0000FT', "X00887XX"])
        .to eq('G0276VC' => 'high', 'T0000FT' => 'high')
    end
  end

  describe '#get_history', vcr: { cassette_name: 'complexity/get_history' } do
    scenario 'happy path' do
      expect(described_class.get_history('S0004FT')).to eq(
        [
          { createdTimeStamp: Time.parse('2021-03-18T14:33:28.364Z'), level: 'low', sourceUser: 'SDICKS_GEN', notes: 'Happy Feet' },
          { createdTimeStamp: Time.parse('2021-03-18T14:34:58.551Z'), level: 'high', sourceUser: 'SDICKS_GEN' },
          { createdTimeStamp: Time.parse('2021-03-18T14:35:20.046Z'), level: 'high', notes: 'Happy Feet' },
        ])
    end
  end
end
