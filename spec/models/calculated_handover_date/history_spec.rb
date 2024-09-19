require "rails_helper"

describe CalculatedHandoverDate::History do
  it 'has a row for creation of and every subsequent change to the handover in reverse order' do
    calculated_handover_date = CalculatedHandoverDate.create(
      responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
      reason: :recall_case,
      offender: create(:offender))
    calculated_handover_date.update!(reason: :determinate_short)
    calculated_handover_date.update!(reason: :additional_isp)

    history = calculated_handover_date.history.to_a
    expect(history.first.reason).to eq('additional_isp')
    expect(history.second.reason).to eq('determinate_short')
    expect(history.third.reason).to eq('recall_case')
  end

  it 'has offender details captured at each change to handover' do
    calculated_handover_date = CalculatedHandoverDate.new(
      responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
      reason: :recall_case,
      offender: create(:offender))
    calculated_handover_date.offender_attributes_to_archive = { 'mappa_level' => 2 }
    calculated_handover_date.save!
    calculated_handover_date.offender_attributes_to_archive = { 'mappa_level' => 5 }
    calculated_handover_date.update!(reason: :determinate_short)

    history = calculated_handover_date.history.to_a
    expect(history.first.mappa_level).to eq(5)
    expect(history.second.mappa_level).to eq(2)
  end

  describe CalculatedHandoverDate::History::Item do
    describe '#earliest_release_date' do
      let(:item) { described_class.new(OpenStruct.new(offender_attributes_to_archive:)) }

      context 'when earliest_release_for_handover exists in offender details' do
        let(:offender_attributes_to_archive) { { "earliest_release_for_handover" => { "name" => "TED", "date" => "01/01/2025" } } }

        it 'uses the ERD from the earliest_release_for_handover field with the type prefixed' do
          expect(item.earliest_release_date).to eq("(TED) 01/01/2025")
        end
      end

      context 'when earliest_release exists in offender details' do
        let(:offender_attributes_to_archive) { { "earliest_release" => { "type" => "THD", "date" => "01/02/2025" } } }

        it 'uses the ERD from the earliest_release field with the type prefixed' do
          expect(item.earliest_release_date).to eq("(THD) 01/02/2025")
        end
      end

      context 'when earliest_release_date exists in offender details' do
        let(:offender_attributes_to_archive) { { "earliest_release_date" => "01/03/2025" } }

        it 'falls back to the ERD from the earliest_release_date field with no type prefixed' do
          expect(item.earliest_release_date).to eq("01/03/2025")
        end
      end
    end

    describe '#updated_at' do
      it 'is the created_at of the version' do
        created_at = 3.minutes.ago
        expect(described_class.new(OpenStruct.new(created_at:)).updated_at).to eq(created_at)
      end
    end
  end
end
