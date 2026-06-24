# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomProfileForm, type: :model do
  subject { described_class.new(status:, description:, working_pattern:) }

  let(:status) { 'active' }
  let(:description) { 'FT' }
  let(:working_pattern) { nil }

  describe 'validations' do
    context 'when status is valid' do
      PomDetail.statuses.each_key do |s|
        it "accepts '#{s}'" do
          subject.status = s
          subject.valid?
          expect(subject.errors[:status]).to be_empty
        end
      end
    end

    context 'when status is invalid' do
      let(:status) { 'unknown' }

      it { is_expected.not_to be_valid }

      it 'has the correct error message' do
        subject.valid?
        expect(subject.errors[:status]).to include('Select a status')
      end
    end

    context 'when status is blank' do
      let(:status) { nil }

      it { is_expected.not_to be_valid }
    end

    context 'when description is valid' do
      %w[FT PT].each do |desc|
        it "accepts '#{desc}'" do
          subject.description = desc
          subject.valid?
          expect(subject.errors[:description]).to be_empty
        end
      end
    end

    context 'when description is invalid' do
      let(:description) { 'XX' }

      it { is_expected.not_to be_valid }

      it 'has the correct error message' do
        subject.valid?
        expect(subject.errors[:description]).to include('Select full time or part time')
      end
    end

    context 'when full time' do
      let(:description) { 'FT' }
      let(:working_pattern) { nil }

      it 'does not validate working_pattern' do
        expect(subject).to be_valid
      end
    end

    context 'when part time' do
      let(:description) { 'PT' }

      context 'when working_pattern is blank' do
        let(:working_pattern) { nil }

        it { is_expected.not_to be_valid }

        it 'has the correct error message' do
          subject.valid?
          expect(subject.errors[:working_pattern]).to include('Select how many days they will work')
        end
      end

      context 'when working_pattern is invalid' do
        let(:working_pattern) { '0.0' }

        it { is_expected.not_to be_valid }
      end

      context 'when working_pattern is not in range' do
        let(:working_pattern) { '1.0' }

        it { is_expected.not_to be_valid }
      end

      context 'when working_pattern is valid' do
        let(:working_pattern) { '0.5' }

        it { is_expected.to be_valid }
      end
    end
  end

  describe '#part_time?' do
    context 'when description is FT' do
      let(:description) { 'FT' }

      it { is_expected.not_to be_part_time }
    end

    context 'when description is PT' do
      let(:description) { 'PT' }

      it { is_expected.to be_part_time }
    end
  end

  describe '#working_pattern_ratio' do
    context 'when full time' do
      let(:description) { 'FT' }

      it 'returns 1.0' do
        expect(subject.working_pattern_ratio).to eq('1.0')
      end
    end

    context 'when part time' do
      let(:description) { 'PT' }
      let(:working_pattern) { '0.5' }

      it 'returns the working pattern value' do
        expect(subject.working_pattern_ratio).to eq('0.5')
      end
    end
  end
end
