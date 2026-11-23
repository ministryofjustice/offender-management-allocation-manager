HISTORY_SIZE = 10
REFERENCE_TIME = Time.zone.local(2020, 1, 2, 3, 4, 5)

RSpec.describe SarOffenderDataServiceV1 do
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
                                          primary_pom_name: 'OLD_NAME, MOIC', secondary_pom_name: 'SEC_SURNAME, POM',
                                          recommended_pom_type: 'prison', created_by_name: 'JOHN DOE',
                                          primary_pom_reviewed_at: REFERENCE_TIME, reviewed_recommended_pom_type: 'probation'
        )
      end

      let(:fake_allocation_history) do
        (1..(HISTORY_SIZE - 1)).to_a.map do |i|
          build(:allocation_history,
                created_at: REFERENCE_TIME - i.days,
                updated_at: REFERENCE_TIME - i.days,
                prison: 'LEI',
                nomis_offender_id: nomis_offender_id,
                primary_pom_name: 'Conder, Anna',
                primary_pom_reviewed_at: REFERENCE_TIME - i.days,
                reviewed_recommended_pom_type: 'prison')
        end
      end

      context 'with no date filters' do
        it 'returns NOMIS id' do
          expect(result[:nomsNumber]).to eq(nomis_offender_id)
        end

        it 'returns all has_many data' do
          expect(result[:allocationHistory].size).to eq(HISTORY_SIZE)
          expect(result[:earlyAllocations].size).to eq(HISTORY_SIZE)
        end

        it 'returns allocation history newest first by effective timestamp' do
          timestamps = result[:allocationHistory].map { Time.zone.parse(it.fetch('updatedAt')) }
          expect(timestamps).to eq(timestamps.sort.reverse)
        end

        it 'returns early allocations newest first' do
          timestamps = result[:earlyAllocations].map { Time.zone.parse(it.fetch('createdAt')) }
          expect(timestamps).to eq(timestamps.sort.reverse)
        end

        it 'returns all has_one data' do
          expect(result[:calculatedHandoverDate].keys).to include('handoverDate')
          expect(result[:caseInformation].keys).to include('tier')
          expect(result[:handoverProgressChecklist].keys).to include('reviewedOasys')
          expect(result[:responsibility].keys).to include('reasonText')
        end
      end

      context 'with date filters' do
        let(:start_date) { (REFERENCE_TIME - 5.days).to_date }
        let(:end_date) { (REFERENCE_TIME - 3.days).to_date }

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
                expect(result[key].first['createdAt'].to_date).to eq((REFERENCE_TIME - 3.days).to_date)
              end
            end
          end

          describe 'with has_one relationship' do
            %i[
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
            earlyAllocations
          ].each do |key|
            it "returns records within the range for #{key}" do
              expect(result[key].size).to eq(3)
              expect(result[key].last['createdAt'].to_date).to eq((REFERENCE_TIME - 5.days).to_date)
            end

            it "returns records newest first for #{key}" do
              timestamps = result[key].map { Time.zone.parse(it.fetch('createdAt')) }
              expect(timestamps).to eq(timestamps.sort.reverse)
            end
          end
        end
      end

      context 'when returned data require transformations' do
        context 'with allocation history' do
          let(:presented_allocation) { result[:allocationHistory].first }

          it 'omits some attributes' do
            expect(presented_allocation.keys).not_to include('id')
            expect(presented_allocation.keys).not_to include('nomisOffenderId')
            expect(presented_allocation.keys).not_to include('primaryPomNomisId')
            expect(presented_allocation.keys).not_to include('primaryPomName')
            expect(presented_allocation.keys).not_to include('secondaryPomNomisId')
            expect(presented_allocation.keys).not_to include('secondaryPomName')
            expect(presented_allocation.keys).not_to include('createdByName')
          end

          it 'humanizes certain attributes' do
            expect(presented_allocation['event']).to eq('Allocate primary POM')
            expect(presented_allocation['eventTrigger']).to eq('User')
            expect(presented_allocation['recommendedPomType']).to eq('Prison POM')
          end

          it 'humanizes override reasons' do
            expect(presented_allocation['overrideReasons']).to eq('Suitability')
          end

          it 'includes every override reason in the same field' do
            allocation.update!(override_reasons: %w[suitability no_staff].to_json)

            expect(presented_allocation['overrideReasons']).to eq('Suitability, No staff')
          end

          it 'returns nil for an empty list of override reasons' do
            allocation.update!(override_reasons: [].to_json)

            expect(presented_allocation['overrideReasons']).to be_nil
          end

          it 'still reports valid reasons when a stored list contains a null entry' do
            allocation.update!(override_reasons: ['suitability', nil, 'no_staff'].to_json)

            expect(presented_allocation['overrideReasons']).to eq('Suitability, No staff')
          end

          it 'returns the creator last name' do
            expect(presented_allocation['createdByLastname']).to eq('DOE')
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
            expect(case_information.keys).not_to include('roshStartDate')
          end

          it 'returns booleans' do
            expect(case_information['manualEntry']).to eq(false)
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

        context 'with early allocation' do
          let(:early_allocation) { result[:earlyAllocations].last }

          it 'omits some attributes' do
            expect(early_allocation.keys).not_to include('createdByFirstname')
            expect(early_allocation.keys).not_to include('updatedByFirstname')
          end

          it 'humanizes outcome' do
            expect(early_allocation['outcome']).to eq('Eligible')
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

  describe 'allocation history date filtering' do
    let(:nomis_offender_id) { 'A1111AA' }
    let(:start_date) { Date.new(2020, 1, 8) }
    let(:end_date) { Date.new(2020, 1, 12) }
    let(:initial_time) { Time.zone.local(2020, 1, 1, 12) }
    let(:first_update_time) { Time.zone.local(2020, 1, 10, 12) }
    let(:second_update_time) { Time.zone.local(2020, 1, 20, 12) }

    before do
      Timecop.travel(initial_time) do
        offender = create(:offender, nomis_offender_id:, created_at: initial_time, updated_at: initial_time)
        allocation = create(
          :allocation_history,
          offender:,
          nomis_offender_id:,
          prison: 'LEI',
          created_at: initial_time,
          updated_at: initial_time
        )

        Timecop.travel(first_update_time) { allocation.update!(event_trigger: AllocationHistory::MANUAL_CHANGE) }
        Timecop.travel(second_update_time) { allocation.update!(event_trigger: AllocationHistory::LEGAL_STATUS_CHANGED) }
      end
    end

    it 'filters historical states by when each state became effective' do
      history = result[:allocationHistory]
      expect(history.map { Time.zone.parse(it.fetch('updatedAt')).to_date }).to eq([first_update_time.to_date, initial_time.to_date])
    end

    context 'with only an end date' do
      let(:start_date) { nil }
      let(:end_date) { first_update_time.to_date }

      it 'returns every allocation state effective through the end date, newest first' do
        timestamps = result[:allocationHistory].map { Time.zone.iso8601(it.fetch('updatedAt')) }
        expect(timestamps).to eq([first_update_time, initial_time])
      end
    end

    context 'when the offender tracking record was created after the requested range' do
      before do
        tracking_record = Offender.find_by!(nomis_offender_id:)
        tracking_record.update_columns(created_at: Time.zone.local(2020, 2, 1), updated_at: Time.zone.local(2020, 2, 1))
      end

      it 'still returns allocation history from the requested range' do
        expect(result[:allocationHistory].size).to eq(2)
      end
    end
  end

  describe 'review details in persisted allocation history' do
    let(:first_review) { Time.zone.local(2020, 1, 2, 12) }
    let(:second_review) { Time.zone.local(2020, 1, 3, 12) }

    before do
      Timecop.travel(Time.zone.local(2020, 1, 1, 12)) do
        offender = create(:offender, nomis_offender_id:)
        allocation = create(:allocation_history, offender:, nomis_offender_id:, prison: 'LEI')
        Timecop.travel(first_review) do
          allocation.update!(primary_pom_reviewed_at: first_review, reviewed_recommended_pom_type: 'prison')
        end
        Timecop.travel(second_review) do
          allocation.update!(primary_pom_reviewed_at: second_review, reviewed_recommended_pom_type: 'probation')
        end
      end
    end

    it 'returns current, previous and unreviewed states with their own review details' do
      history = result.fetch(:allocationHistory)
      expect(history.map { it.fetch('reviewedRecommendedPomType') }).to eq(['Probation POM', 'Prison POM', nil])
      expect(history.map { |entry| entry['primaryPomReviewedAt'] && Time.zone.parse(entry['primaryPomReviewedAt']) })
        .to eq([second_review, first_review, nil])
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
