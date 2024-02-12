RSpec.describe SarOffenderDataService do
  subject(:result) do
    described_class.find(nomis_offender_id, start_date, end_date)
  end

  let(:history_size) { 10 }
  let(:nomis_offender_id) { 'A1111AA' }

  describe '.find' do
    context 'with no matching offender record' do
      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end

    context 'with matching offender record' do
      before do
        create(:offender, nomis_offender_id: nomis_offender_id)
        create_historic_list(:audit_event, { nomis_offender_id: nomis_offender_id })
        create(:calculated_early_allocation_status, nomis_offender_id: nomis_offender_id)
        create(:calculated_handover_date, nomis_offender_id: nomis_offender_id)
        create(:case_information, nomis_offender_id: nomis_offender_id)
        create_historic_list(:early_allocation, { nomis_offender_id: nomis_offender_id })
        create_historic_list(:email_history, { nomis_offender_id: nomis_offender_id }, trait: :auto_early_allocation)
        create(:handover_progress_checklist, nomis_offender_id: nomis_offender_id)
        create_historic_list(:offender_email_sent, { nomis_offender_id: nomis_offender_id })
        create(:parole_record, nomis_offender_id: nomis_offender_id)
        create(:responsibility, nomis_offender_id: nomis_offender_id)
        create_historic_list(:victim_liaison_officer, { nomis_offender_id: nomis_offender_id })

        allow_any_instance_of(AllocationHistory).to receive(:get_old_versions).and_return(fake_allocation_history)
      end

      let!(:allocation) do
        create(:allocation_history, prison: 'LEI', nomis_offender_id: nomis_offender_id, primary_pom_name: 'OLD_NAME, MOIC')
      end

      let(:fake_allocation_history) do
        (1..(history_size - 1)).to_a.map do |i|
          build(:allocation_history,
                updated_at: Time.zone.now - i.days,
                prison: 'LEI',
                nomis_offender_id: nomis_offender_id,
                primary_pom_name: 'OLD_NAME, MOIC')
        end
      end

      context 'with no date filters' do
        let(:start_date) { nil }
        let(:end_date) { nil }

        it 'returns all data' do
          expect(result[:allocationHistory].size).to eq(history_size)
          expect(result[:auditEvents].size).to eq(history_size)
          expect(result[:earlyAllocations].size).to eq(history_size)
          expect(result[:emailHistories].size).to eq(history_size)
          expect(result[:offenderEmailSent].size).to eq(history_size)
          expect(result[:victimLiaisonOfficers].size).to eq(history_size)
        end
      end

      # TODO: customised filter depending on event or state
      #  TODO: test single objects too
      context 'with date filters' do
        let(:start_date) { Time.zone.today - 5 }
        let(:end_date) { Time.zone.today - 3 }

        it 'returns filtered data' do
          expect(result[:allocationHistory].size).to eq(3)
          expect(result[:auditEvents].size).to eq(3)
          expect(result[:earlyAllocations].size).to eq(3)
          expect(result[:emailHistories].size).to eq(3)
          expect(result[:offenderEmailSent].size).to eq(3)
          expect(result[:victimLiaisonOfficers].size).to eq(3)
        end
      end
    end
  end

  def create_historic_list(name, attributes, trait: nil)
    if trait
      create_list(name, history_size, trait, **attributes) do |item, i|
        item.created_at = Time.zone.now - i.days
      end
    else
      create_list(name, history_size, **attributes) do |item, i|
        item.created_at = Time.zone.now - i.days
      end
    end
  end
end
