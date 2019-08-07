require 'rails_helper'

describe Nomis::Models::SentenceDetail, model: true do
  let(:date) { Date.new(2019, 2, 3) }
  let(:override) { Date.new(2019, 5, 3) }

  describe '#automatic_release_date' do
    context 'when override present' do
      before do
        subject.automatic_release_date = date
        subject.automatic_release_override_date = override
      end

      it 'overrides' do
        expect(subject.automatic_release_date).to eq(override)
      end
    end

    context 'without override' do
      before do
        subject.automatic_release_date = date
      end

      it 'uses original' do
        expect(subject.automatic_release_date).to eq(date)
      end
    end
  end

  describe '#conditional_release_date' do
    context 'when override present' do
      before do
        subject.conditional_release_date = date
        subject.conditional_release_override_date = override
      end

      it 'overrides' do
        expect(subject.conditional_release_date).to eq(override)
      end
    end

    context 'without override' do
      before do
        subject.conditional_release_date = date
      end

      it 'uses original' do
        expect(subject.conditional_release_date).to eq(date)
      end
    end
  end
end
