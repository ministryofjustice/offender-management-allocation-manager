HISTORY_SIZE = 10
REFERENCE_TIME = Time.zone.local(2020, 1, 2, 3, 4, 5)

RSpec.describe SarOffenderDataService do
  subject(:result) do
    described_class.new(nomis_offender_id, start_date, end_date).find
  end

  let(:nomis_offender_id) { 'A1111AA' }
  let(:start_date) { nil }
  let(:end_date) { nil }

  describe '.find' do
    context 'with no matching offender record' do
      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end

    context 'with matching offender record' do
      before do
        create_historic(:offender, nomis_offender_id, offset: 7.days)
        create_historic_list(:audit_event, nomis_offender_id)
        create_historic(:calculated_early_allocation_status, nomis_offender_id)
        create_historic(:calculated_handover_date, nomis_offender_id, reason: 'immigration_case', responsibility: 'CustodyWithCom')
        create_historic(:case_information, nomis_offender_id, local_delivery_unit: build(:local_delivery_unit, name: 'Leeds'))
        create_historic_list(:early_allocation, nomis_offender_id)
        create_historic_list(:email_history, nomis_offender_id, trait: :auto_early_allocation)
        create_historic(:handover_progress_checklist, nomis_offender_id)
        create_historic_list(:offender_email_sent, nomis_offender_id, offender_email_type: 'handover_date')
        create_historic(:responsibility, nomis_offender_id)
        create_historic_list(:victim_liaison_officer, nomis_offender_id)

        allow_any_instance_of(AllocationHistory).to receive(:get_old_versions).and_return(fake_allocation_history)
      end

      let!(:allocation) do
        create(
          :allocation_history, :override, prison: 'LEI', nomis_offender_id: nomis_offender_id,
                                          primary_pom_name: 'OLD_NAME, MOIC', secondary_pom_name: 'SEC_SURNAME, POM'
        )
      end

      let(:fake_allocation_history) do
        (1..(HISTORY_SIZE - 1)).to_a.map do |i|
          build(:allocation_history,
                created_at: REFERENCE_TIME - i.days,
                updated_at: REFERENCE_TIME - i.days,
                prison: 'LEI',
                nomis_offender_id: nomis_offender_id,
                primary_pom_name: 'Conder, Anna')
        end
      end

      context 'with no date filters' do
        it 'returns NOMIS id' do
          expect(result[:nomsNumber]).to eq(nomis_offender_id)
        end

        it 'returns all has_many data' do
          expect(result[:allocationHistory].size).to eq(HISTORY_SIZE)
          expect(result[:auditEvents].size).to eq(HISTORY_SIZE + 1) # +1 as `let!(:allocation)` adds an extra audit record
          expect(result[:earlyAllocations].size).to eq(HISTORY_SIZE)
          expect(result[:offenderEmailSent].size).to eq(HISTORY_SIZE)
        end

        it 'returns all has_one data' do
          expect(result[:calculatedEarlyAllocationStatus].keys).to include('eligible')
          expect(result[:calculatedHandoverDate].keys).to include('handoverDate')
          expect(result[:caseInformation].keys).to include('tier')
          expect(result[:handoverProgressChecklist].keys).to include('reviewedOasys')
          expect(result[:responsibility].keys).to include('reasonText')
        end
      end

      context 'with date filters' do
        let(:start_date) { (REFERENCE_TIME - 5.days).to_date }
        let(:end_date) { (REFERENCE_TIME - 3.days).to_date }

        describe 'offender record' do
          context "with date range before creation" do
            let(:start_date) { (REFERENCE_TIME - 9.days).to_date }
            let(:end_date) { (REFERENCE_TIME - 8.days).to_date }

            it 'returns nil' do
              expect(result).to eq(nil)
            end
          end

          context "with date range straddling creation" do
            let(:start_date) { (REFERENCE_TIME - 3.days).to_date }
            let(:end_date) { (REFERENCE_TIME + 3.days).to_date }

            it 'returns record' do
              expect(result).not_to eq(nil)
            end
          end

          context "with date range after creation" do
            let(:start_date) { (REFERENCE_TIME + 3.days).to_date }
            let(:end_date) { (REFERENCE_TIME + 6.days).to_date }

            it 'returns record' do
              expect(result).not_to eq(nil)
            end
          end
        end

        # State-based: The record's influence extends beyond it's creation time until
        # it is superceded by the next record
        # Algorithm: Return last created before the date range, and any created within the range
        # Days ago   ..10..9..8..7..6..5..4..3..2..1..0
        # Date range .................<.......>........
        # Return     ...............x..x..x..x.........
        describe 'state-based records' do
          describe 'with has_many relationship' do
            %i[
              allocationHistory
            ].each do |key|
              it "returns records within the range and the last previous for #{key}" do
                expect(result[key].size).to eq(4)
                expect(result[key].first['createdAt'].to_date).to eq((REFERENCE_TIME - 6.days).to_date)
              end
            end
          end

          describe 'with has_one relationship' do
            %i[
              calculatedEarlyAllocationStatus
              calculatedHandoverDate
              caseInformation
              handoverProgressChecklist
              responsibility
            ].each do |key|
              context "with date range before #{key} creation" do
                let(:start_date) { (REFERENCE_TIME - 5.days).to_date }
                let(:end_date) { (REFERENCE_TIME - 3.days).to_date }

                it 'returns nil' do
                  expect(result[key]).to eq(nil)
                end
              end

              context "with date range straddling #{key} creation" do
                let(:start_date) { (REFERENCE_TIME - 3.days).to_date }
                let(:end_date) { (REFERENCE_TIME + 3.days).to_date }

                it 'returns record' do
                  expect(result[key]).not_to eq(nil)
                end
              end

              context "with date range after #{key} creation" do
                let(:start_date) { (REFERENCE_TIME + 3.days).to_date }
                let(:end_date) { (REFERENCE_TIME + 6.days).to_date }

                it 'returns record' do
                  expect(result[key]).not_to eq(nil)
                end
              end
            end
          end
        end

        # Event-based: The record's influence is confined to it's own creation time - it
        # indicates an event that took place at a certain time
        # Algorithm: Return any created within the range
        # Days ago   ..10..9..8..7..6..5..4..3..2..1..0
        # Date range .................<.......>........
        # Return     ..................x..x..x.........
        describe 'event-based records (all are has_many)' do
          %i[
            auditEvents
            offenderEmailSent
            earlyAllocations
          ].each do |key|
            it "returns records within the range for #{key}" do
              expect(result[key].size).to eq(3)
              expect(result[key].first['createdAt'].to_date).to eq((REFERENCE_TIME - 5.days).to_date)
            end
          end
        end
      end

      context 'when returned data require transformations' do
        context 'with allocation history' do
          let(:presented_allocation) { result[:allocationHistory].last }

          it 'omits some attributes' do
            expect(presented_allocation.keys).not_to include('id')
            expect(presented_allocation.keys).not_to include('nomisOffenderId')
            expect(presented_allocation.keys).not_to include('primaryPomNomisId')
            expect(presented_allocation.keys).not_to include('primaryPomName')
            expect(presented_allocation.keys).not_to include('secondaryPomNomisId')
            expect(presented_allocation.keys).not_to include('secondaryPomName')
          end

          it 'returns the primary POM last name' do
            expect(presented_allocation['primaryPomLastName']).to eq('OLD_NAME')
          end

          it 'returns the secondary POM last name' do
            expect(presented_allocation['secondaryPomLastName']).to eq('SEC_SURNAME')
          end

          it 'humanizes event and event_trigger' do
            expect(presented_allocation['event']).to eq('Allocate primary POM')
            expect(presented_allocation['eventTrigger']).to eq('User')
          end

          it 'humanizes override reasons' do
            expect(presented_allocation['overrideReasons']).to eq('Suitability')
          end

          it 'returns nil attributes' do
            expect(presented_allocation['message']).to be_nil
          end
        end

        context 'with case information' do
          let(:case_information) { result[:caseInformation] }

          it 'omits some attributes' do
            expect(case_information.keys).not_to include('id')
            expect(case_information.keys).not_to include('nomisOffenderId')
            expect(case_information.keys).not_to include('crn')
            expect(case_information.keys).not_to include('localDeliveryUnitId')
            expect(case_information.keys).not_to include('lduCode')
          end

          it 'returns booleans' do
            expect(case_information['manualEntry']).to eq(true)
            expect(case_information['enhancedResourcing']).to eq(false)
          end

          it 'returns the LDU name' do
            expect(case_information['localDeliveryUnit']).to eq('Leeds')
          end
        end

        context 'with calculated handover date' do
          let(:calculated_handover_date) { result[:calculatedHandoverDate] }

          it 'omits some attributes' do
            expect(calculated_handover_date.keys).not_to include('id')
            expect(calculated_handover_date.keys).not_to include('nomisOffenderId')
          end

          it 'returns the reason string' do
            expect(calculated_handover_date['reason']).to eq('Immigration Case')
          end

          it 'returns the responsibility string' do
            expect(calculated_handover_date['responsibility']).to eq('POM')
          end
        end

        context 'with audit event' do
          let(:audit_event) { result[:auditEvents].last }

          it 'omits some attributes' do
            expect(audit_event.keys).not_to include('data')
          end
        end

        context 'with early allocation' do
          let(:early_allocation) { result[:earlyAllocations].last }

          it 'humanizes outcome' do
            expect(early_allocation['outcome']).to eq('Eligible')
          end
        end

        context 'with offender email sent' do
          let(:offender_email_sent) { result[:offenderEmailSent].last }

          it 'humanizes offender email type' do
            expect(offender_email_sent['offenderEmailType']).to eq('Handover date')
          end
        end

        context 'with responsibility' do
          let(:responsibility) { result[:responsibility] }

          it 'humanizes reason' do
            expect(responsibility['reason']).to eq('Less than 10 months to serve')
          end
        end
      end
    end
  end

  def create_historic(name, nomis_offender_id, offset: 0, **factory_opts)
    Timecop.travel REFERENCE_TIME - offset do
      create(name, nomis_offender_id: nomis_offender_id, **factory_opts)
    end
  end

  def create_historic_list(name, nomis_offender_id, trait: nil, **factory_opts)
    args_array = [name, trait].compact

    HISTORY_SIZE.times do |i|
      Timecop.travel REFERENCE_TIME - i.days do
        create(*args_array, nomis_offender_id: nomis_offender_id, **factory_opts)
      end
    end
  end
end
