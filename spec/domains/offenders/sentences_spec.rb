require "rails_helper"

describe Offenders::Sentences do
  subject(:sentences) { described_class.new(booking_id: 123_456) }

  let(:sentence_sequences) { [] }

  before { allow(Sentences).to receive(:for).with(booking_id: 123_456).and_return(sentence_sequences) }

  describe "#sentenced_to_additional_future_isp?" do
    context 'when there is more than one indeterminate sentence but they have the same start date' do
      let(:sentence_sequences) { [double(indeterminate?: true, sentence_start_date: 1.year.ago.beginning_of_day), double(indeterminate?: true, sentence_start_date: 1.year.ago.beginning_of_day)] }

      it 'returns false' do
        expect(sentences.sentenced_to_additional_future_isp?).to be_falsey
      end
    end

    context 'when there is more than one indeterminate sentence and they have different start dates' do
      let(:sentence_sequences) { [double(indeterminate?: true, sentence_start_date: 2.years.ago), double(indeterminate?: true, sentence_start_date: 1.year.ago)] }

      it 'returns true' do
        expect(sentences.sentenced_to_additional_future_isp?).to be_truthy
      end
    end

    context 'when there is one ISP sentence' do
      let(:sentence_sequences) { [double(indeterminate?: true, sentence_start_date: 1.day.ago)] }

      it 'returns false' do
        expect(sentences.sentenced_to_additional_future_isp?).to be_falsey
      end
    end

    context 'when there are no ISP sentences' do
      let(:sentence_sequences) { [double(indeterminate?: false, sentence_start_date: 1.day.ago)] }

      it 'returns false' do
        expect(sentences.sentenced_to_additional_future_isp?).to be_falsey
      end
    end
  end

  describe "#single_sentence?" do
    context 'when there is only one sentence of any kind' do
      let(:sentence_sequences) { [double] }

      it 'returns true' do
        expect(sentences.single_sentence?).to be_truthy
      end
    end

    context 'when there are no sentences of any kind' do
      let(:sentence_sequences) { [] }

      it 'returns false' do
        expect(sentences.single_sentence?).to be_falsey
      end
    end

    context 'when there are is more than one sentence of any kind' do
      let(:sentence_sequences) { [double, double] }

      it 'returns false' do
        expect(sentences.single_sentence?).to be_falsey
      end
    end
  end

  describe "#concurrent_sentence_of_12_months_or_under?" do
    context 'when there is only one sentence' do
      let(:sentence_sequences) { [double] }

      it 'returns false' do
        expect(sentences.concurrent_sentence_of_12_months_or_under?).to be_falsey
      end
    end

    context 'when there is more than one sentance but neither have a duration of 12 months or under' do
      let(:sentence_sequences) { [double(duration: 13.months), double(duration: 2.years)] }

      it 'returns false' do
        expect(sentences.concurrent_sentence_of_12_months_or_under?).to be_falsey
      end
    end

    context 'when there is more than one sentance and at least one has a duration of 12 months or under' do
      let(:sentence_sequences) { [double(duration: 2.months), double(duration: 2.years)] }

      it 'returns false' do
        expect(sentences.concurrent_sentence_of_12_months_or_under?).to be_truthy
      end
    end
  end

  describe "#concurrent_sentence_of_20_months_or_over?" do
    context 'when there is only one sentence' do
      let(:sentence_sequences) { [double] }

      it 'returns false' do
        expect(sentences.concurrent_sentence_of_20_months_or_over?).to be_falsey
      end
    end

    context 'when there is more than one sentance but neither have a duration of 20 months or over' do
      let(:sentence_sequences) { [double(duration: 13.months), double(duration: 19.months)] }

      it 'returns false' do
        expect(sentences.concurrent_sentence_of_20_months_or_over?).to be_falsey
      end
    end

    context 'when there is more than one sentance and at least one has a duration of 20 months or over' do
      let(:sentence_sequences) { [double(duration: 2.months), double(duration: 2.years)] }

      it 'returns false' do
        expect(sentences.concurrent_sentence_of_20_months_or_over?).to be_truthy
      end
    end
  end
end
