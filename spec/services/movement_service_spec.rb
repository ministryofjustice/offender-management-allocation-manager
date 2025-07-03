require 'rails_helper'

describe MovementService, type: :feature do
  let!(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }

  let(:new_offender_court) { build(:movement, offenderNo: 'G4273GI', fromAgency: 'COURT')   }
  let(:new_offender_nil) { build(:movement, offenderNo: 'G4273GI', fromAgency: nil)   }
  let(:transfer_out) { build(:movement, offenderNo: 'G4273GI', directionCode: 'OUT', movementType: 'TRN')   }

  let(:movements) do
    [
      { "offenderNo": "G0595VU", "createDateTime": "2019-02-20T12:17:21.542454", "fromAgency": "SWI", "toAgency": "OUT", "movementType": "REL", "directionCode": "OUT", "movementDate": "2019-02-20", "movementTime": "12:14:01" },
      { "offenderNo": "A5019DY", "createDateTime": "2019-02-20T11:06:06.626913", "fromAgency": "DTI", "toAgency": "OUT", "movementType": "REL", "directionCode": "OUT", "movementDate": "2019-02-20", "movementTime": "11:03:46" },
    ]
  end

  before do
    stub_agencies(HmppsApi::PrisonApi::AgenciesApi::HOSPITAL_AGENCY_TYPE)
    stub_request(:get, "#{ApiHelper::T3}/movements?fromDateTime=2018-02-20T00:00&movementDate=2019-02-20")
      .to_return(body: movements.to_json)

    stub_pom(
      build(:pom, staffId: 485_926, firstName: 'MOIC', lastName: 'POM'),
      emails: ['test@example.com']
    )

    stub_offender(
      build(:nomis_offender, prisonerNumber: 'G7266VD', prisonId: 'LEI', firstName: 'John', lastName: 'Doe')
    )
  end

  it "can get recent movements" do
    movements = described_class.movements_on(Date.iso8601('2019-02-20'))
    expect(movements).to be_a(Array)
    expect(movements.length).to eq(2)
    expect(movements.first).to be_a(HmppsApi::Movement)
  end

  it "can ignore movements OUT" do
    processed = described_class.process_movement(transfer_out)
    expect(processed).to be false
  end

  context 'when from_agency is outside the prison estate' do
    it "can ignore new offenders arriving at prison when from_agency is outside the prison estate" do
      processed = described_class.process_movement(new_offender_court)
      expect(processed).to be false
    end
  end

  it "can ignore new offenders arriving at prison when from_agency is nil" do
    processed = described_class.process_movement(new_offender_nil)
    expect(processed).to be false
  end

  describe "processing an offender transfer" do
    let(:transfer_adm_no_to_agency) { build(:movement, offenderNo: 'G7266VD', toAgency: 'COURT')   }
    let(:transfer_in) { build(:movement, offenderNo: 'G7266VD', directionCode: 'IN', movementType: 'ADM', fromAgency: 'VEI', toAgency: 'CFI')   }
    let(:admission) { build(:movement, offenderNo: 'G7266VD', toAgency: 'LEI', fromAgency: 'COURT')   }

    let!(:existing_allocation) { create(:allocation_history, nomis_offender_id: 'G7266VD', prison: 'LEI')   }
    let(:existing_alloc_transfer) { build(:movement, offenderNo: 'G7266VD', fromAgency: 'PRI', toAgency: 'LEI')   }

    it "can process transfers where offender already allocated at new prison" do
      expect(existing_allocation.prison).to eq('LEI')
      processed = described_class.process_movement(existing_alloc_transfer)
      expect(processed).to be false
    end

    context 'when processing an admission' do
      let(:transfer_adm) { build(:movement, offenderNo: 'G7266VD', fromAgency: 'PRI', toAgency: 'PVI')   }
      let(:updated_allocation) { existing_allocation.reload }

      it "can process transfer movements IN" do
        expect(described_class.process_movement(transfer_adm)).to eq(true)

        expect(updated_allocation.event).to eq 'deallocate_primary_pom'
        expect(updated_allocation.event_trigger).to eq 'offender_transferred'
        expect(updated_allocation.primary_pom_name).to be_nil
      end
    end

    it "can process a movement with invalid 'to' agency" do
      processed = described_class.process_movement(transfer_adm_no_to_agency)
      expect(processed).to be false
    end

    it "can starts an open prison transfer" do
      open_prison_transfer = build(:movement, offenderNo: 'G7266VD', toAgency: 'HDI')

      processed = described_class.process_movement(open_prison_transfer)
      expect(processed).to be true
    end

    it "can do an open prison transfer with an inactive allocation" do
      open_prison_transfer = build(:movement, offenderNo: 'G7266VD', toAgency: 'HDI')

      existing_allocation.deallocate_offender_after_transfer
      processed = described_class.process_movement(open_prison_transfer)
      expect(processed).to be true
    end

    it "can process a movement with no 'to' agency" do
      processed = described_class.process_movement(admission)
      expect(processed).to be false
    end

    it "will process offenders on remand" do
      # Originally we did not want to process non-convicted offenders, so offenders on remand
      # who were moved were not de-allocated (as they should never have been allocated).  This
      # optimisation has come back to bite us as it is entirely possible someone who is allocated
      # could be switched to remand immediately, so now we expect this to succeed.
      allow(OffenderService).to receive(:get_offender).and_return(build(:hmpps_api_offender, legalStatus: "REMAND"))
      processed = described_class.process_movement(transfer_in)
      expect(processed).to be true
    end

    it "will ignore an unknown movement type" do
      unknown_movement_type = build(:movement, offenderNo: 'G4273GI', movementType: 'TMP')
      processed = described_class.process_movement(unknown_movement_type)
      expect(processed).to be false
    end

    context "when offender moving from a hospital to a new prison" do
      subject(:processed) { described_class.process_movement(transfer) }

      let(:transfer) do
        build(:movement, offenderNo: 'G7266VD', directionCode: 'IN', movementType: 'ADM',
                         fromAgency: 'HOS1', toAgency: 'GTI')
      end

      it 'returns true', flaky: true do
        expect(processed).to be true
      end

      it 'de-allocates offender', flaky: true do
        processed
        expect(existing_allocation.reload.active?).to eq(false)
      end
    end
  end

  describe "processing an offender release" do
    let!(:case_info) { create(:case_information, offender: build(:offender, nomis_offender_id: 'G7266VD')) }
    let!(:allocation) { create(:allocation_history, prison: 'LEI', nomis_offender_id: 'G7266VD') }

    def pom_tester(valid_release)
      mailer = double(:mailer)
      expect(PomMailer).to receive(:with)
              .with(email: "test@example.com",
                    pom_name: "Moic",
                    offender_name: "Doe, John",
                    nomis_offender_id: valid_release.offender_no,
                    prison_name: 'Leeds (HMP)',
                    url: "http://localhost:3000/prisons/LEI/staff/485926/caseload")
              .and_return(double(:pom_mailer_with, offender_deallocated: mailer))
      expect(mailer).to receive(:deliver_later)
    end

    context 'with a valid release movement' do
      let(:updated_allocation) { AllocationHistory.find_by(nomis_offender_id: valid_release.offender_no) }
      let(:processed) { described_class.process_movement(valid_release) }

      let(:valid_release) do
        build(:movement, offenderNo: 'G7266VD', directionCode: 'OUT', movementType: 'REL', toAgency: 'OUT', fromAgency: from_agency)
      end

      before { pom_tester(valid_release) }

      context 'and from a male prison' do
        let(:from_agency) { 'BAI' }

        it "can process movements" do
          expect(HmppsApi::ComplexityApi).not_to receive(:inactivate).with(valid_release.offender_no)
          expect(processed).to be true
          expect(CaseInformation.where(nomis_offender_id: valid_release.offender_no)).to be_empty
          expect(updated_allocation.event_trigger).to eq 'offender_released'
          expect(updated_allocation.prison).to eq 'LEI'
        end
      end

      context 'and from a female prison' do
        let(:from_agency) { 'AGI' }

        it "can process movements" do
          expect(HmppsApi::ComplexityApi).to receive(:inactivate).with(valid_release.offender_no)
          expect(processed).to be true
          expect(CaseInformation.where(nomis_offender_id: valid_release.offender_no)).to be_empty
          expect(updated_allocation.event_trigger).to eq 'offender_released'
          expect(updated_allocation.prison).to eq 'LEI'
        end
      end

      context 'and for hospital restricted patient' do
        let(:from_agency) { 'HOS1' }

        it "can process movements", flaky: true do
          expect(processed).to be true
          expect(CaseInformation.where(nomis_offender_id: valid_release.offender_no)).to be_empty
          expect(updated_allocation.event_trigger).to eq 'offender_released'
          expect(updated_allocation.prison).to eq 'LEI'
        end
      end

      context 'and from open prison with inactive allocation' do
        let(:from_agency) { 'BAI' }

        before { allocation.deallocate_offender_after_release }

        it "can process movements" do
          expect(processed).to be true
        end
      end
    end

    context 'with invalid release movements' do
      let(:invalid_release1) { build(:movement, offenderNo: 'G7266VD', directionCode: 'OUT', movementType: 'REL', toAgency: 'LEI')   }
      let(:invalid_release2) { build(:movement, offenderNo: 'G7266VD', directionCode: 'OUT', movementType: 'REL', fromAgency: 'COURT')   }
      let(:invalid_release3) { build(:movement, offenderNo: 'G7266VD', directionCode: 'OUT', movementType: 'REL', fromAgency: 'BASDON')   }

      it "can ignore invalid release movements" do
        processed = described_class.process_movement(invalid_release1)
        expect(processed).to be false

        processed = described_class.process_movement(invalid_release2)
        expect(processed).to be false

        processed = described_class.process_movement(invalid_release3)
        expect(processed).to be false
      end
    end
  end

  describe "processing offenders moved to/from immigration estates" do
    before do
      create(:allocation_history, prison: 'LEI', nomis_offender_id: 'G7266VD')
    end

    let(:allocation) { AllocationHistory.find_by(nomis_offender_id: 'G7266VD') }

    let(:immigration_movement) do
      build(:movement, offenderNo: 'G7266VD', directionCode: direction_code, movementDate: Date.new(2020, 1, 6).to_s,
                       movementType: movement_type, fromAgency: from_agency, toAgency: to_agency)
    end

    context 'when movement is a transfer' do
      let(:case_info) { create(:case_information, nomis_offender_id: 'G7266VD') }

      context 'when the from_agency is MHI' do
        context 'with the offender going into a prison estate' do
          let(:from_agency) { 'MHI' }
          let(:to_agency) { 'PVI' }
          let(:movement_type) { 'ADM' }
          let(:direction_code) { 'IN' }

          it 'does not process movement' do
            processed = described_class.process_movement(immigration_movement)
            expect(processed).to be true
          end
        end

        context 'with the offender moving OUT of the prison estate' do
          let(:from_agency) { 'MHI' }
          let(:to_agency) { 'IMM' }
          let(:movement_type) { 'TRN' }
          let(:direction_code) { 'IN' }

          it 'can process release movement for offender' do
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

          it 'can process release movement for offender' do
            processed = described_class.process_movement(immigration_movement)

            expect(CaseInformation.where(nomis_offender_id: immigration_movement.offender_no)).to be_empty
            expect(allocation.event_trigger).to eq 'offender_transferred'
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

          it 'can release movement' do
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
