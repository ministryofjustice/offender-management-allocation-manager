require 'rails_helper'

describe MovementService do
  include ActiveJob::TestHelper

  let!(:new_offender_court) { create(:movement, offender_no: 'G4273GI', from_agency: 'COURT')   }
  let!(:new_offender_nil) { create(:movement, offender_no: 'G4273GI', from_agency: nil)   }
  let!(:transfer_out) { create(:movement, offender_no: 'G4273GI', direction_code: 'OUT', movement_type: 'TRN')   }

  it "can get recent movements",
     vcr: { cassette_name: :movement_service_recent_spec }  do
    movements = described_class.movements_on(Date.iso8601('2019-02-20'))
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Movement)
  end

  it "can filter transfer type results",
     vcr: { cassette_name: :movement_service_filter_type_spec }  do
    movements = described_class.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::MovementType::TRANSFER]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(0)
  end

  it "can filter admissions",
     vcr: { cassette_name: :movement_service_filter_adm_spec }  do
    movements = described_class.movements_on(
      Date.iso8601('2019-03-12'),
      type_filters: [Nomis::MovementType::ADMISSION]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Movement)
    expect(movements.first.movement_type).to eq(Nomis::MovementType::ADMISSION)
  end

  it "can filter release type results",
     vcr: { cassette_name: :movement_service_filter_release_spec }  do
    movements = described_class.movements_on(
      Date.iso8601('2019-02-20'),
      type_filters: [Nomis::MovementType::RELEASE]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Movement)
    expect(movements.first.movement_type).to eq(Nomis::MovementType::RELEASE)
  end

  it "can filter results by direction IN",
     vcr: { cassette_name: :movement_service_filter_direction_in_spec }  do
    movements = described_class.movements_on(
      Date.iso8601('2019-03-12'),
      direction_filters: [Nomis::MovementDirection::IN]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(1)
    expect(movements.first).to be_kind_of(Nomis::Movement)
    expect(movements.first.direction_code).to eq(Nomis::MovementDirection::IN)
  end

  it "can filter results by direction OUT",
     vcr: { cassette_name: :movement_service_filter_direction_out_spec }  do
    movements = described_class.movements_on(
      Date.iso8601('2019-02-20'),
      direction_filters: [Nomis::MovementDirection::OUT]
    )
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(Nomis::Movement)
    expect(movements.first.direction_code).to eq(Nomis::MovementDirection::OUT)
  end

  it "can ignore movements OUT",
     vcr: { cassette_name: :movement_service_ignore_out_spec }  do
    processed = described_class.process_movement(transfer_out)
    expect(processed).to be false
  end

  it "can ignore new offenders arriving at prison when from_agency is outside the prison estate",
     vcr: { cassette_name: :movement_service_ignore_new__from_court_spec }  do
    processed = described_class.process_movement(new_offender_court)
    expect(processed).to be false
  end

  it "can ignore new offenders arriving at prison when from_agency is nil",
     vcr: { cassette_name: :movement_service_ignore_new_from_nil_spec }  do
    processed = described_class.process_movement(new_offender_nil)
    expect(processed).to be false
  end

  describe "processing an offender transfer" do
    let!(:transfer_adm_no_to_agency) { create(:movement, offender_no: 'G4273GI', to_agency: 'COURT')   }
    let!(:transfer_in) { create(:movement, offender_no: 'G4273GI', direction_code: 'IN', movement_type: 'ADM', from_agency: 'VEI', to_agency: 'CFI')   }
    let!(:admission) { create(:movement, offender_no: 'G4273GI', to_agency: 'LEI', from_agency: 'COURT')   }

    let!(:existing_allocation) { create(:allocation, nomis_offender_id: 'G4273GI', prison: 'LEI')   }
    let!(:existing_alloc_transfer) { create(:movement, offender_no: 'G4273GI', from_agency: 'PRI', to_agency: 'LEI')   }

    it "can process transfers were offender already allocated at new prison",
       vcr: { cassette_name: :movement_service_transfer_in_existing_spec }  do
      expect(existing_allocation.prison).to eq('LEI')
      processed = described_class.process_movement(existing_alloc_transfer)
      expect(processed).to be false
    end

    context 'when processing an admission' do
      let(:transfer_adm) { create(:movement, offender_no: 'G4273GI', from_agency: 'PRI', to_agency: 'PVI')   }
      let(:updated_allocation) { existing_allocation.reload }

      it "can process transfer movements IN",
         vcr: { cassette_name: :movement_service_transfer_in_spec }  do
        expect(described_class.process_movement(transfer_adm)).to eq(true)

        expect(updated_allocation.event).to eq 'deallocate_primary_pom'
        expect(updated_allocation.event_trigger).to eq 'offender_transferred'
        expect(updated_allocation.primary_pom_name).to be_nil
      end
    end

    it "can process a movement with invalid 'to' agency",
       vcr: { cassette_name: :movement_service_transfer_in_spec }  do
      processed = described_class.process_movement(transfer_adm_no_to_agency)
      expect(processed).to be false
    end

    it "can starts an open prison transfer",
       vcr: { cassette_name: :movement_service_transfer_to_open_spec }  do
      open_prison_transfer = create(:movement, offender_no: 'G4273GI', to_agency: 'HDI')

      expect {
        processed = described_class.process_movement(open_prison_transfer)
        expect(processed).to be true
      }.to change(enqueued_jobs, :count).by(1)
    end

    it "can process a movement with no 'to' agency",
       vcr: { cassette_name: :movement_service_admission_in_spec }  do
      processed = described_class.process_movement(admission)
      expect(processed).to be false
    end

    it "will not process offenders on remand",
       vcr: { cassette_name: :movement_service_transfer_in__not_convicted_spec }  do
      # Originally we did not want to process non-convicted offenders, so offenders on remand
      # who were moved were not de-allocated (as they should never have been allocated).  This
      # optimisation has come back to bite us as it is entirely possible someone who is allocated
      # could be switched to remand immediately, so now we expect this to succeed.
      allow(OffenderService).to receive(:get_offender).and_return(Nomis::Offender.new.tap{ |o|
        o.convicted_status = "Remand"
      })
      processed = described_class.process_movement(transfer_in)
      expect(processed).to be true
    end

    it "will ignore an unknown movement type",
       vcr: { cassette_name: :movement_service_unknown_spec }  do
      unknown_movement_type = create(:movement, offender_no: 'G4273GI', movement_type: 'TMP')
      processed = described_class.process_movement(unknown_movement_type)
      expect(processed).to be false
    end
  end

  describe "processing an offender release" do
    let!(:valid_release) { create(:movement, offender_no: 'G4273GI', direction_code: 'OUT', movement_type: 'REL', to_agency: 'OUT', from_agency: 'BAI')   }
    let!(:invalid_release1) { create(:movement, offender_no: 'G4273GI', direction_code: 'OUT', movement_type: 'REL', to_agency: 'LEI')   }
    let!(:invalid_release2) { create(:movement, offender_no: 'G4273GI', direction_code: 'OUT', movement_type: 'REL', from_agency: 'COURT')   }

    let!(:case_info) { create(:case_information, nomis_offender_id: 'G4273GI') }
    let!(:allocation) { create(:allocation, nomis_offender_id: 'G4273GI') }

    it "can process release movements", vcr: { cassette_name: :movement_service_process_release_spec }  do
      processed = described_class.process_movement(valid_release)
      updated_allocation = Allocation.find_by(nomis_offender_id: valid_release.offender_no)

      expect(CaseInformationService.get_case_information([valid_release.offender_no])).to be_empty
      expect(updated_allocation.event_trigger).to eq 'offender_released'
      expect(updated_allocation.prison).to eq 'LEI'
      expect(processed).to be true
    end

    it "can ignore invalid release movements", vcr: { cassette_name: :movement_service_process_release_invalid_spec }  do
      processed = described_class.process_movement(invalid_release1)
      expect(processed).to be false

      processed = described_class.process_movement(invalid_release2)
      expect(processed).to be false
    end
  end

  describe "processing offenders moved to/from immigration estates" do
    before do
      create(:allocation, nomis_offender_id: 'G4273GI')
    end

    let(:allocation) { Allocation.find_by(nomis_offender_id: 'G4273GI') }

    let(:immigration_movement) do
      create(:movement, offender_no: 'G4273GI', direction_code: direction_code, create_date_time: Date.new(2020, 1, 6),
                        movement_type: movement_type, from_agency: from_agency, to_agency: to_agency)
    end

    context 'when movement is a transfer' do
      let(:case_info) { create(:case_information, nomis_offender_id: 'G4273GI') }

      context 'when the from_agency is MHI' do
        context 'with the offender going into a prison estate' do
          let(:from_agency) { 'MHI' }
          let(:to_agency){ 'PVI' }
          let(:movement_type) { 'ADM' }
          let(:direction_code) { 'IN' }

          it 'does not process movement' do
            processed = described_class.process_movement(immigration_movement)
            expect(processed).to be false
          end
        end

        context 'with the offender moving OUT of the prison estate' do
          let(:from_agency) { 'MHI' }
          let(:to_agency) { 'IMM' }
          let(:movement_type) { 'TRN' }
          let(:direction_code) { 'IN' }

          it 'can process release movement for offender', vcr: { cassette_name: :immigration_movement_service_successful } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformationService.get_case_information([immigration_movement.offender_no])).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end
      end

      context 'when the from_agency is IMM' do
        context 'with the offender going into a prison estate' do
          let(:from_agency) { 'IMM' }
          let(:to_agency) { 'PVI' }
          let(:movement_type) { 'TRN' }
          let(:direction_code) { 'IN' }

          it 'does not process movement' do
            processed = described_class.process_movement(immigration_movement)
            expect(processed).to be false
          end
        end

        context 'when the offender is moving OUT of the prison estate' do
          let(:from_agency) { 'IMM' }
          let(:to_agency) { 'MHI' }
          let(:movement_type) { 'ADM' }
          let(:direction_code) { 'IN' }

          it 'can process release movement for offender', vcr: { cassette_name: :immigration_movement_service_successful } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformationService.get_case_information([immigration_movement.offender_no])).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end
      end
    end

    context 'when movement is a release' do
      context 'when offender moving to an immigration centre' do
        context 'when the from_agency is MHI' do
          let(:from_agency) { 'MHI' }
          let(:to_agency) { 'OUT' }
          let(:movement_type) { 'REL' }
          let(:direction_code) { 'OUT' }

          it 'can release movement' do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformationService.get_case_information([immigration_movement.offender_no])).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end

        context 'when the from_agency is IMM' do
          let(:from_agency) { 'IMM' }
          let(:to_agency) { 'OUT' }
          let(:movement_type) { 'REL' }
          let(:direction_code) { 'OUT' }

          it 'can release movement' do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformationService.get_case_information([immigration_movement.offender_no])).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end
      end
    end
  end
end
