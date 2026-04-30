# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SortableAllocation do
  let(:test_class) do
    Class.new do
      include SortableAllocation

      def initialize(offender)
        @offender = offender
      end
    end
  end

  let(:offender) { double(:offender, complexity_level:) }
  let(:instance) { test_class.new(offender) }

  describe '#complexity_level_number' do
    context 'when complexity_level is nil' do
      let(:complexity_level) { nil }

      it 'returns 0' do
        expect(instance.complexity_level_number).to eq(0)
      end
    end

    context 'when complexity_level is low' do
      let(:complexity_level) { 'low' }

      it 'returns 1' do
        expect(instance.complexity_level_number).to eq(1)
      end
    end

    context 'when complexity_level is medium' do
      let(:complexity_level) { 'medium' }

      it 'returns 2' do
        expect(instance.complexity_level_number).to eq(2)
      end
    end

    context 'when complexity_level is high' do
      let(:complexity_level) { 'high' }

      it 'returns 3' do
        expect(instance.complexity_level_number).to eq(3)
      end
    end
  end

  describe '#high_complexity?' do
    context 'when complexity_level is nil' do
      let(:complexity_level) { nil }

      it 'returns false' do
        expect(instance.high_complexity?).to be(false)
      end
    end

    context 'when complexity_level is high' do
      let(:complexity_level) { 'high' }

      it 'returns true' do
        expect(instance.high_complexity?).to be(true)
      end
    end
  end
end
