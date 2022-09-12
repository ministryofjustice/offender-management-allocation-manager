require 'rails_helper'

RSpec.describe OffenderWithPrisonTimelinePresenter do
  describe '#additional_information' do
    let(:prison_timeline) do
      { "prisonPeriod" => prison_periods }
    end

    let(:mpc_offender) do
      build(
        :mpc_offender,
        prison: prison,
        offender: offender,
        prison_record: double(:nomis_offender, recalled?: recalled)
      )
    end

    let(:prison) { build(:prison) }
    let(:offender) { build(:offender) }
    let(:recalled) { false }

    subject { described_class.new(mpc_offender, prison_timeline).additional_information }

    # New to custody – never been in prison before
    context 'when never been in any prison before the current one' do
      let(:prison_periods) { [{"prisons" => [prison.code]}] }

      it 'New to custody' do
        expect(subject).to eq(['New to custody'])
      end
    end

    context 'when been in prison before' do
      # New to this prison – been in prison before, but first time here
      context 'when first time here' do
        let(:prison_periods) do
          [
            {'prisons' => ['ABC', 'DEF']},
            {"prisons" => [prison.code]}
          ]
        end

        it 'New to this prison' do
          expect(subject).to eq(['New to this prison'])
        end
      end

      # Returning to this prison – been in this prison before
      context 'when returning to here' do
        let(:prison_periods) do
          [
            {"prisons" => ['XYZ', prison.code]},
            {'prisons' => ['ABC', 'DEF']},
            {"prisons" => [prison.code]}
          ]
        end

        it 'Returning to this prison' do
          expect(subject).to eq(['Returning to this prison'])
        end
      end

      # Recall – been recalled to this prison
      context 'when recalled to here' do
        let(:recalled) { true }

        # New to this prison – been in prison before, but first time here
        context 'when first time here' do
          let(:prison_periods) do
            [
              {'prisons' => ['ABC', 'DEF']},
              {"prisons" => [prison.code]}
            ]
          end

          it 'Recalled - New to this prison' do
            expect(subject).to eq(['Recall', 'New to this prison'])
          end
        end

        # Returning to this prison – been in this prison before
        context 'when returning to here' do
          let(:prison_periods) do
            [
              {"prisons" => ['XYZ', prison.code]},
              {'prisons' => ['ABC', 'DEF']},
              {"prisons" => [prison.code]}
            ]
          end

          it 'Recalled - Returning to this prison' do
            expect(subject).to eq(['Recall', 'Returning to this prison'])
          end
        end
      end
    end
  end
end