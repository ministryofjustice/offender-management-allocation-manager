require 'rails_helper'

describe MovementService, type: :feature do
  let(:new_offender_court) { build(:movement, offenderNo: 'G4273GI', fromAgency: 'COURT')   }
  let(:new_offender_nil) { build(:movement, offenderNo: 'G4273GI', fromAgency: nil)   }
  let(:transfer_out) { build(:movement, offenderNo: 'G4273GI', directionCode: 'OUT', movementType: 'TRN')   }

  it "can get recent movements",
     vcr: { cassette_name: 'prison_api/movement_service_recent_spec' }  do
    movements = described_class.movements_on(Date.iso8601('2019-02-20'))
    expect(movements).to be_kind_of(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_kind_of(HmppsApi::Movement)
  end

  it "can ignore movements OUT",
     vcr: { cassette_name: 'prison_api/movement_service_ignore_out_spec' }  do
    processed = described_class.process_movement(transfer_out)
    expect(processed).to be false
  end

  it "can ignore new offenders arriving at prison when from_agency is outside the prison estate",
     vcr: { cassette_name: 'prison_api/movement_service_ignore_new__from_court_spec' }  do
    processed = described_class.process_movement(new_offender_court)
    expect(processed).to be false
  end

  it "can ignore new offenders arriving at prison when from_agency is nil",
     vcr: { cassette_name: 'prison_api/movement_service_ignore_new_from_nil_spec' }  do
    processed = described_class.process_movement(new_offender_nil)
    expect(processed).to be false
  end

  describe "processing an offender transfer" do
    let(:transfer_adm_no_to_agency) { build(:movement, offenderNo: 'G4273GI', toAgency: 'COURT')   }
    let(:transfer_in) { build(:movement, offenderNo: 'G4273GI', directionCode: 'IN', movementType: 'ADM', fromAgency: 'VEI', toAgency: 'CFI')   }
    let(:admission) { build(:movement, offenderNo: 'G4273GI', toAgency: 'LEI', fromAgency: 'COURT')   }

    let!(:existing_allocation) { create(:allocation_history, nomis_offender_id: 'G4273GI', prison: 'LEI')   }
    let(:existing_alloc_transfer) { build(:movement, offenderNo: 'G4273GI', fromAgency: 'PRI', toAgency: 'LEI')   }

    it "can process transfers were offender already allocated at new prison",
       vcr: { cassette_name: 'prison_api/movement_service_transfer_in_existing_spec' }  do
      expect(existing_allocation.prison).to eq('LEI')
      processed = described_class.process_movement(existing_alloc_transfer)
      expect(processed).to be false
    end

    context 'when processing an admission' do
      let(:transfer_adm) { build(:movement, offenderNo: 'G4273GI', fromAgency: 'PRI', toAgency: 'PVI')   }
      let(:updated_allocation) { existing_allocation.reload }

      it "can process transfer movements IN",
         vcr: { cassette_name: 'prison_api/movement_service_transfer_in_spec' }  do
        expect(described_class.process_movement(transfer_adm)).to eq(true)

        expect(updated_allocation.event).to eq 'deallocate_primary_pom'
        expect(updated_allocation.event_trigger).to eq 'offender_transferred'
        expect(updated_allocation.primary_pom_name).to be_nil
      end
    end

    it "can process a movement with invalid 'to' agency",
       vcr: { cassette_name: 'prison_api/movement_service_transfer_in_spec' }  do
      processed = described_class.process_movement(transfer_adm_no_to_agency)
      expect(processed).to be false
    end

    it "can starts an open prison transfer",
       vcr: { cassette_name: 'prison_api/movement_service_transfer_to_open_spec' }  do
      open_prison_transfer = build(:movement, offenderNo: 'G4273GI', toAgency: 'HDI')

      processed = described_class.process_movement(open_prison_transfer)
      expect(processed).to be true
    end

    it "can do an open prison transfer with an inactive allocation",
       vcr: { cassette_name: 'prison_api/movement_service_transfer_to_open_spec' }  do
      open_prison_transfer = build(:movement, offenderNo: 'G4273GI', toAgency: 'HDI')

      existing_allocation.dealloate_offender_after_transfer
      processed = described_class.process_movement(open_prison_transfer)
      expect(processed).to be true
    end

    it "can process a movement with no 'to' agency",
       vcr: { cassette_name: 'prison_api/movement_service_admission_in_spec' }  do
      processed = described_class.process_movement(admission)
      expect(processed).to be false
    end

    it "will not process offenders on remand",
       vcr: { cassette_name: 'prison_api/movement_service_transfer_in__not_convicted_spec' }  do
      # Originally we did not want to process non-convicted offenders, so offenders on remand
      # who were moved were not de-allocated (as they should never have been allocated).  This
      # optimisation has come back to bite us as it is entirely possible someone who is allocated
      # could be switched to remand immediately, so now we expect this to succeed.
      allow(OffenderService).to receive(:get_offender).and_return(build(:hmpps_api_offender, convictedStatus: "Remand"))
      processed = described_class.process_movement(transfer_in)
      expect(processed).to be true
    end

    it "will ignore an unknown movement type",
       vcr: { cassette_name: 'prison_api/movement_service_unknown_spec' }  do
      unknown_movement_type = build(:movement, offenderNo: 'G4273GI', movementType: 'TMP')
      processed = described_class.process_movement(unknown_movement_type)
      expect(processed).to be false
    end
  end

  describe "processing an offender release" do
    let!(:case_info) { create(:case_information, offender: build(:offender, nomis_offender_id: 'G4273GI')) }
    let!(:allocation) { create(:allocation_history, nomis_offender_id: 'G4273GI') }

    context 'with a valid release movement' do
      let(:valid_release) { build(:movement, offenderNo: 'G4273GI', directionCode: 'OUT', movementType: 'REL', toAgency: 'OUT', fromAgency: 'BAI')   }

      before do
        expect_any_instance_of(PomMailer)
            .to receive(:offender_deallocated)
                    .with(email: "pom@digital.justice.gov.uk",
                          pom_name: "Moic",
                          offender_name: "Abbella, Ozullirn",
                          nomis_offender_id: valid_release.offender_no,
                          prison_name: 'HMP Leeds',
                          url: "http://localhost:3000/prisons/LEI/staff/485926/caseload")
                    .and_call_original
      end

      it "can process release movements", vcr: { cassette_name: 'prison_api/movement_service_process_release_spec' }  do
        processed = described_class.process_movement(valid_release)
        updated_allocation = AllocationHistory.find_by(nomis_offender_id: valid_release.offender_no)

        expect(CaseInformation.where(nomis_offender_id: valid_release.offender_no)).to be_empty
        expect(updated_allocation.event_trigger).to eq 'offender_released'
        expect(updated_allocation.prison).to eq 'LEI'
        expect(processed).to be true
      end

      it "can do an open prison release with an inactive allocation",
         vcr: { cassette_name: 'prison_api/movement_service_process_release_spec' }  do
        allocation.deallocate_offender_after_release
        processed = described_class.process_movement(valid_release)

        expect(processed).to be true
      end
    end

    context 'with invalid release movements' do
      let(:invalid_release1) { build(:movement, offenderNo: 'G4273GI', directionCode: 'OUT', movementType: 'REL', toAgency: 'LEI')   }
      let(:invalid_release2) { build(:movement, offenderNo: 'G4273GI', directionCode: 'OUT', movementType: 'REL', fromAgency: 'COURT')   }

      it "can ignore invalid release movements", vcr: { cassette_name: 'prison_api/movement_service_process_release_invalid_spec' }  do
        processed = described_class.process_movement(invalid_release1)
        expect(processed).to be false

        processed = described_class.process_movement(invalid_release2)
        expect(processed).to be false
      end
    end
  end

  describe "processing offenders moved to/from immigration estates" do
    before do
      create(:allocation_history, nomis_offender_id: 'G4273GI')
    end

    let(:allocation) { AllocationHistory.find_by(nomis_offender_id: 'G4273GI') }

    let(:immigration_movement) do
      build(:movement, offenderNo: 'G4273GI', directionCode: direction_code, movementDate: Date.new(2020, 1, 6).to_s,
                       movementType: movement_type, fromAgency: from_agency, toAgency: to_agency)
    end

    context 'when movement is a transfer' do
      let(:case_info) { create(:case_information, nomis_offender_id: 'G4273GI') }

      context 'when the from_agency is MHI' do
        context 'with the offender going into a prison estate' do
          let(:from_agency) { 'MHI' }
          let(:to_agency) { 'PVI' }
          let(:movement_type) { 'ADM' }
          let(:direction_code) { 'IN' }

          it 'does not process movement',
             vcr: { cassette_name: 'prison_api/immigration_transfer_from_MHI_to_prison_not_successful' } do
            processed = described_class.process_movement(immigration_movement)
            expect(processed).to be false
          end
        end

        context 'with the offender moving OUT of the prison estate' do
          let(:from_agency) { 'MHI' }
          let(:to_agency) { 'IMM' }
          let(:movement_type) { 'TRN' }
          let(:direction_code) { 'IN' }

          it 'can process release movement for offender',
             vcr: { cassette_name: 'prison_api/immigration_transfer_from_MHI_to_IMM_successful' } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformation.where(nomis_offender_id: immigration_movement.offender_no)).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end

        context 'with the offender moving from a prison to MHI or IMM' do
          let(:from_agency) { 'LEI' }
          let(:to_agency) { 'MHI' }
          let(:movement_type) { 'ADM' }
          let(:direction_code) { 'IN' }

          it 'can process release movement for offender',
             vcr: { cassette_name: 'prison_api/immigration_transfer_from_prison_to_IMM_successful' } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformation.where(nomis_offender_id: immigration_movement.offender_no)).to be_empty
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

          it 'does not process movement',
             vcr: { cassette_name: 'prison_api/immigration_transfer_from_IMM_to_prison_not_successful' } do
            processed = described_class.process_movement(immigration_movement)
            expect(processed).to be false
          end
        end

        context 'when the offender is moving OUT of the prison estate' do
          let(:from_agency) { 'IMM' }
          let(:to_agency) { 'MHI' }
          let(:movement_type) { 'ADM' }
          let(:direction_code) { 'IN' }

          it 'can process release movement for offender',
             vcr: { cassette_name: 'prison_api/immigration_transfer_from_IMM_to_MHI_successful' } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformation.where(nomis_offender_id: immigration_movement.offender_no)).to be_empty
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

          it 'can release movement',
             vcr: { cassette_name: 'prison_api/immigration_release_from_MHI_to_OUT_successful' } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformation.where(nomis_offender_id: immigration_movement.offender_no)).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end

        context 'when the from_agency is IMM' do
          let(:from_agency) { 'IMM' }
          let(:to_agency) { 'OUT' }
          let(:movement_type) { 'REL' }
          let(:direction_code) { 'OUT' }

          it 'can release movement',
             vcr: { cassette_name: 'prison_api/immigration_release_from_IMM_to_OUT_successful' } do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformation.where(nomis_offender_id: immigration_movement.offender_no)).to be_empty
            expect(allocation.event_trigger).to eq 'offender_released'
            expect(processed).to be true
          end
        end
      end
    end
  end
end
