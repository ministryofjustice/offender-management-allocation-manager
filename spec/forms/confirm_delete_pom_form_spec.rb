# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConfirmDeletePomForm, type: :model do
  subject { described_class.new(confirmation:) }

  describe 'validations' do
    context 'when confirmation is yes' do
      let(:confirmation) { 'yes' }

      it { is_expected.to be_valid }

      it 'is confirmed' do
        expect(subject).to be_confirmed
      end
    end

    context 'when confirmation is no' do
      let(:confirmation) { 'no' }

      it { is_expected.to be_valid }

      it 'is not confirmed' do
        expect(subject).not_to be_confirmed
      end
    end

    context 'when confirmation is blank' do
      let(:confirmation) { '' }

      it { is_expected.not_to be_valid }

      it 'has the correct error message' do
        subject.valid?
        expect(subject.errors[:confirmation]).to include('Select yes if you want to remove this POM')
      end
    end

    context 'when confirmation is nil' do
      let(:confirmation) { nil }

      it { is_expected.not_to be_valid }
    end
  end
end
