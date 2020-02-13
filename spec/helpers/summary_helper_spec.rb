require 'rails_helper'

describe SummaryHelper do
  describe 'the next delius import' do
    let(:result) { Timecop.travel(today) { delius_schedule_for(arrival) } }

    context 'when today is Monday' do
      let(:today) { Date.parse('Monday 18 Nov 2019') }

      context 'when the prisoner arrived today' do
        let(:arrival) { today }

        it 'is tomorrow' do
          expect(result).to eq('Tomorrow')
        end
      end

      context 'when the prisoner arrived yesterday' do
        let(:arrival) { today - 1 }

        it 'is tomorrow' do
          expect(result).to eq('Today')
        end
      end

      context 'when the prisoner arrived today at 4pm' do
        let(:arrival) { today + 16.hours }

        it 'is tomorrow' do
          expect(result).to eq('Tomorrow')
        end
      end

      context 'when the prisoner arrived yesterday at 4pm' do
        let(:arrival) { today - 8.hours }

        it 'is tomorrow' do
          expect(result).to eq('Today')
        end
      end
    end

    context 'when today is Saturday' do
      let(:today) { Date.parse('Saturday 16 Nov 2019') }

      context 'when the prisoner arrived today' do
        let(:arrival) { today }

        it 'is Monday' do
          expect(result).to eq('Monday')
        end
      end

      context 'when the prisoner arrived yesterday' do
        let(:arrival) { today - 1 }

        it 'is Monday' do
          expect(result).to eq('Monday')
        end
      end
    end
  end
end
