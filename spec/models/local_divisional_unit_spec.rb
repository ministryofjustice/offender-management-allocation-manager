# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LocalDivisionalUnit, type: :model do
  it {
    expect(subject).to validate_presence_of :name
    expect(subject).to validate_presence_of :code
    expect(subject).not_to validate_presence_of :email_address
  }

  describe '#code' do
    let(:ldu) { build(:local_divisional_unit, code: code) }

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
