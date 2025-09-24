# frozen_string_literal: true

require 'rspec'

RSpec.describe KeyworkerService do
  describe '.get_keyworker' do
    let(:offender_no) { 'A1234BC' }

    context 'when there is a key worker allocation' do
      let(:api_response) do
        {
          'allocations' => [{
            'policy' => { 'code' => described_class::KW_POLICY_CODE },
            'prison' => { 'code' => 'LEI', 'description' => 'Leeds (HMP)' },
            'staffMember' => { 'staffId' => 123_456, 'firstName' => 'JOHN', 'lastName' => 'SMITH' }
          }]
        }
      end

      before do
        allow(HmppsApi::KeyworkerApi).to receive(:get_keyworker)
          .with(offender_no).and_return(api_response)
      end

      it 'returns a deserialized keyworker' do
        result = described_class.get_keyworker(offender_no)
        expect(result).to be_a(HmppsApi::KeyworkerDetails)

        expect(result.full_name).to eq('John Smith')
        expect(result.staff_id).to eq(123_456)
      end
    end

    context 'when there is no key worker allocation' do
      let(:api_response) { { 'allocations' => [] } }

      before do
        allow(HmppsApi::KeyworkerApi).to receive(:get_keyworker)
          .with(offender_no).and_return(api_response)
      end

      it 'returns a null keyworker' do
        result = described_class.get_keyworker(offender_no)
        expect(result).to be_a(HmppsApi::NullKeyworker)

        expect(result.full_name).to eq('None assigned')
      end
    end

    context 'when the API fails' do
      before do
        allow(HmppsApi::KeyworkerApi).to receive(:get_keyworker)
          .with(offender_no).and_return(nil)
      end

      it 'returns a null keyworker' do
        result = described_class.get_keyworker(offender_no)
        expect(result).to be_a(HmppsApi::NullKeyworker)

        expect(result.full_name).to eq('Data not available')
      end
    end
  end
end
