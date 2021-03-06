# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocalDivisionalUnit, type: :model do
  it {
    expect(subject).to validate_presence_of :name
    expect(subject).to validate_presence_of :code
    expect(subject).not_to validate_presence_of :email_address
  }

  context 'with and without emails' do
    before do
      create(:local_divisional_unit, email_address: nil)
      create(:local_divisional_unit, email_address: '')
      create(:local_divisional_unit, email_address: 'test@example.com')
    end

    describe '#with_email_address' do
      let(:expected) { described_class.last }

      it 'returns just the filled-in version' do
        expect(described_class.with_email_address.to_a).to eq([expected])
      end
    end

    describe '#without_email_address' do
      let(:expected) { described_class.first(2) }

      it 'returns just the filled-in version' do
        expect(described_class.without_email_address.to_a).to match_array(expected)
      end
    end
  end

  describe '#code' do
    let(:ldu) { build(:local_divisional_unit, code: code) }

    context 'with blank' do
      let(:code) { '' }

      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    context 'with non-alpha' do
      let(:code) { "ND4\t" }

      it 'is invalid' do
        expect(ldu).not_to be_valid
      end
    end

    context 'with upper-case and numbers' do
      let(:code) { 'ND143A' }

      it 'is valid' do
        expect(ldu).to be_valid
      end
    end

    context 'with lower-case and numbers' do
      let(:code) { 'nd143a' }

      it 'is valid' do
        expect(ldu).to be_valid
      end
    end
  end
end
