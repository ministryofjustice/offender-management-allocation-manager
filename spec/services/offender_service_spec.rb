require 'rails_helper'

describe OffenderService, type: :feature do
  describe '#get_offender (mocked API calls)' do
    let(:offender_no) { "FAKENUMBER" }
    let(:offender) { double :offender }
    let(:api_offender) { double :api_offender, prison_id: "FAKE" }
    let(:prison) { instance_double Prison, :prison }

    before do
      allow(Offender).to receive(:find_or_create_by)
      allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender)
      allow(Prison).to receive(:find_by)
      allow(MpcOffender).to receive(:new)
    end

    it 'can ignore legal status when getting MOIC offender' do
      allow(Offender).to receive(:find_or_create_by).and_return(offender)
      described_class.get_offender(offender_no, ignore_legal_status: true)

      expect(HmppsApi::PrisonApi::OffenderApi).to have_received(:get_offender).with(offender_no,
                                                                                    ignore_legal_status: true)
    end
  end

  describe '#get_offender' do
    it "gets a single offender", vcr: { cassette_name: 'prison_api/offender_service_single_offender_spec' } do
      nomis_offender_id = 'G7266VD'

      create(:case_information, :welsh, offender: build(:offender, nomis_offender_id: nomis_offender_id), tier: 'C', enhanced_resourcing: false)
      offender = described_class.get_offender(nomis_offender_id)

      expect(offender.tier).to eq 'C'
      expect(offender.conditional_release_date).to eq(Date.new(2040, 1, 27))
      expect(offender.main_offence).to eq 'Robbery'
      expect(offender.handover_type).to eq 'missing'
    end

    it "returns nil if offender record not found", vcr: { cassette_name: 'prison_api/offender_service_single_offender_not_found_spec' } do
      nomis_offender_id = 'AAA121212CV4G4GGVV'

      offender = described_class.get_offender(nomis_offender_id)
      expect(offender).to be_nil
    end

    context 'when offender is not in prison' do
      let(:offender) { build(:nomis_offender, inOutStatus: 'OUT', prisonId: 'OUT') }

      before do
        stub_offender(offender)
      end

      it 'returns nil as the offender is outside of our service' do
        expect(described_class.get_offender(offender.fetch(:prisonerNumber))).to be_nil
      end
    end

    context 'when offender is in an unknown prison' do
      # MHI - Morton Hall immigration centre
      let(:offender) { build(:nomis_offender, prisonId: 'MHI') }

      before do
        stub_offender(offender)
      end

      it 'returns nil as the offender cannot be handled' do
        expect(described_class.get_offender(offender.fetch(:prisonerNumber))).to be_nil
      end
    end
  end

  describe 'get_mappa_details' do
    before do
      allow(HmppsApi::ManagePomCasesAndDeliusApi).to receive(:get_mappa_details)
        .and_return(api_mappa)
    end

    let(:result) { described_class.get_mappa_details('ABC123') }

    let(:api_mappa) do
      {
        "category" => 3,
        "categoryDescription" => "MAPPA Cat 1",
        "level" => 1,
        "levelDescription" => "MAPPA Level 1",
        "notes" => "string",
        "officer" => {
          "code" => "AN001A",
          "forenames" => "Sheila Linda",
          "surname" => "Hancock",
          "unallocated" => true
        },
        "probationArea" => {
          "code" => "ABC123",
          "description" => "Some description"
        },
        "reviewDate" => "2021-04-27",
        "startDate" => "2021-01-27",
        "team" => {
          "code" => "ABC123",
          "description" => "Some description"
        }
      }
    end

    it 'gets short description' do
      expect(result[:short_description]).to eq('CAT 3/LEVEL 1')
    end

    it 'gets start date' do
      expect(result[:start_date]).to eq(Date.new(2021, 1, 27))
    end

    context 'with absent reviewDate' do
      before { api_mappa.delete('reviewDate') }

      it 'uses nil for review_date' do
        expect(result[:review_date]).to eq(nil)
      end
    end
  end

  describe 'get_probation_record' do
    before do
      allow(HmppsApi::ManagePomCasesAndDeliusApi).to receive(:get_probation_record)
        .and_return(probation_record)
    end

    let(:result) { described_class.get_probation_record(nomis_offender_id) }

    let(:crn) { 'ABC123' }
    let(:nomis_offender_id) { 'ZY000X' }
    let(:tier) { 'A' }
    let(:resourcing) { 'NORMAL' }
    let(:team_code) { 'TC000' }
    let(:team_description) { 'A team description' }
    let(:ldu_code) { 'LDU000' }
    let(:ldu_description) { 'An LDU description' }
    let(:manager_code) { 'M000' }
    let(:manager_forename) { 'Borris' }
    let(:manager_middle_name) { 'Brian' }
    let(:manager_surname) { 'Beckker' }
    let(:manager_email) { 'borris@beckker.me' }
    let(:mappa_level) { 0 }

    let(:probation_record) do
      {
        crn: crn,
        nomsId: nomis_offender_id,
        currentTier: tier,
        resourcing: resourcing,
        manager: {
          team: {
            code: team_code,
            description: team_description,
            localDeliveryUnit: {
              code: ldu_code,
              description: ldu_description
            }
          },
          code: manager_code,
          name: {
            forename: manager_forename,
            middleName: manager_middle_name,
            surname: manager_surname
          },
          email: manager_email
        },
        mappaLevel: mappa_level,
        vloAssigned: true
      }
    end

    context 'when not found' do
      before do
        allow(HmppsApi::ManagePomCasesAndDeliusApi).to receive(:get_probation_record)
          .and_raise(Faraday::ResourceNotFound.new(nil))
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end

    context 'when found' do
      let(:expected_hash) do
        {
          crn: crn,
          noms_id: nomis_offender_id,
          tier: tier,
          resourcing: resourcing,
          manager: {
            team: {
              code: team_code,
              description: team_description,
              local_delivery_unit: {
                code: ldu_code,
                description: ldu_description
              }
            },
            code: manager_code,
            name: {
              forename: manager_forename,
              middle_name: manager_middle_name,
              surname: manager_surname
            },
            email: manager_email
          },
          mappa_level: mappa_level,
          vlo_assigned: true
        }
      end

      it 'returns expected hash' do
        expect(result).to eq(expected_hash)
      end
    end
  end
end
