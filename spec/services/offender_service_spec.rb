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
        stub_auth_token
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
        stub_auth_token
        stub_offender(offender)
      end

      it 'returns nil as the offender cannot be handled' do
        expect(described_class.get_offender(offender.fetch(:prisonerNumber))).to be_nil
      end
    end
  end

  describe '#get_community_data' do
    # This offender has been set up in nDelius test especially for this test
    let(:nomis_offender_id) { 'A5194DY' }

    # This test can only be run inside the VPN as nDelius test isn't globally accessible
    context 'when hitting API', :vpn_only, vcr: { cassette_name: 'delius/get_community_data' } do
      it 'gets some data' do
        expect(described_class.get_community_data(nomis_offender_id))
            .to eq('crn' => "X349420",
                   'ldu_code' => "N07NPSA",
                   'mappa_levels' => [],
                   'noms_no' => nomis_offender_id,
                   'offender_manager' => "TestUpdate01Surname, TestUpdate01Forname",
                   'enhanced_resourcing' => true,
                   'team_name' => "OMU A",
                   'tier' => "B-2",
                   'active_vlo' => false)
      end
    end

    describe '[with some stubbing]' do
      before do
        stub_auth_token
      end

      describe 'enhanced_handover? attr:' do
        subject(:value) { described_class.get_community_data(nomis_offender_id).fetch(:enhanced_resourcing) }

        before do
          # Transitioning from mocking of APIs to stubbing using mocks
          stub_community_offender(nomis_offender_id, build(:community_data))
          allow(HmppsApi::CommunityApi).to receive(:get_latest_resourcing).and_raise(Faraday::ResourceNotFound.allocate)
          allow(HmppsApi::CommunityApi).to receive(:get_offender_registrations).and_return({})
        end

        it 'uses latest resourcing info for the given offender from Delius' do
          value # invoke it
          expect(HmppsApi::CommunityApi).to have_received(:get_latest_resourcing).with(nomis_offender_id)
        end

        it 'is true when offender has not had a CAS assessment yet' do
          expect(value).to eq true
        end

        it 'is true when enhancedResourcing is true' do
          allow(HmppsApi::CommunityApi).to receive(:get_latest_resourcing).and_return('enhancedResourcing' => true)
          expect(value).to eq true
        end

        it 'is false when enhancedResourcing is false' do
          allow(HmppsApi::CommunityApi).to receive(:get_latest_resourcing).and_return('enhancedResourcing' => false)
          expect(value).to eq false
        end

        it 'defaults to true when a draft CAS assessment is in the "Not Assessed" state' do
          allow(HmppsApi::CommunityApi).to receive(:get_latest_resourcing).and_return({})
          expect(value).to eq true
        end
      end

      context 'without MAPPA data' do
        context 'with a single allocated COM' do
          before do
            stub_community_offender(nomis_offender_id, build(:community_data,
                                                             offenderManagers: [{ active: true, staff: { unallocated: false, surname: 'Jones', forenames: 'Ruth Mary' } }]))
          end

          it 'gets the surname and forenames' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:offender_manager))
                .to eq('Jones, Ruth Mary')
          end
        end

        context 'with multiple allocated COMs' do
          before do
            stub_community_offender(nomis_offender_id, build(:community_data,
                                                             offenderManagers: [
                                                               { active: false, staff: { unallocated: false, surname: 'Jones', forenames: 'Ruth Mary' } },
                                                               { active: true, staff: { unallocated: false, surname: 'Smith', forenames: 'Mel Griff' } },
                                                               { active: false, staff: { unallocated: false, surname: 'Rabbit', forenames: 'Richard Oliver' } },
                                                             ]))
          end

          it 'gets the surname and forenames' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:offender_manager)).to eq('Smith, Mel Griff')
          end
        end
      end

      context 'with MAPPA data' do
        before do
          stub_community_offender(nomis_offender_id,
                                  build(:community_data,
                                        currentTier: 'A',
                                        otherIds: { crn: 'X5657657' },
                                        offenderManagers: [
                                          {
                                            team: { code: 'N07GHGF',
                                                    description: 'Thing',
                                                    localDeliveryUnit: { code: 'LDU123' } },
                                            active: true,
                                            staff: { unallocated: true } }
                                        ]), registrations)
        end

        context 'with an inactive registration' do
          let(:registrations) { [build(:community_registration, active: false)] }

          it 'gets some data' do
            expect(described_class.get_community_data(nomis_offender_id))
                .to eq('noms_no' => nomis_offender_id,
                       'tier' => 'A',
                       'crn' => 'X5657657',
                       'offender_manager' => nil,
                       'enhanced_resourcing' => true,
                       'mappa_levels' => [],
                       'team_name' => 'Thing',
                       'ldu_code' => 'LDU123',
                       'active_vlo' => false)
          end
        end

        context 'with an active non-MAPPA registration' do
          let(:registrations) { [build(:community_registration)] }

          it 'gets empty mappa levels' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:mappa_levels))
                .to eq([])
          end
        end

        context 'with an active MAPPA registration' do
          let(:registrations) { [build(:community_registration, :mappa_2)] }

          it 'gets mappa_levels' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:mappa_levels))
                .to eq([2])
          end
        end
      end

      context 'with VLO data' do
        before do
          stub_community_offender(nomis_offender_id, community_data, registrations)
        end

        let(:community_data) { build(:community_data, enhancedResourcing: true) }

        context 'with inactive registrations' do
          let(:registrations) do
            [
              build(:community_registration, :type_invi, active: false),
              build(:community_registration, :type_daso, active: false)
            ]
          end

          it 'deems no active VLO' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:active_vlo))
                .to eq(false)
          end
        end

        context 'with an active INVI registration' do
          let(:registrations) { [build(:community_registration, :type_invi)] }

          it 'deems an active VLO' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:active_vlo))
                .to eq(true)
          end
        end

        context 'with an active DASO registration' do
          let(:registrations) { [build(:community_registration, :type_daso)] }

          it 'deems an active VLO' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:active_vlo))
                .to eq(true)
          end
        end
      end
    end
  end

  describe '#get_com' do
    # This offender has been set up in nDelius test especially for this test
    let(:nomis_offender_id) { 'A5194DY' }

    # This test can only be run inside the VPN as nDelius test isn't globally accessible
    context 'when hitting API', :vpn_only, vcr: { cassette_name: 'delius/get_all_offender_managers_data' } do
      it 'gets some data' do
        expected = {
          'name' => 'TestUpdate01Surname, TestUpdate01Forname',
          'email' => 'test-update-01-email@example.org ',
          'ldu_code' => 'N07NPSA',
          'team_name' => 'OMU A',
          'is_responsible' => true,
          'is_unallocated' => false,
        }

        expect(described_class.get_com(nomis_offender_id)).to eq expected
      end
    end

    context 'with stubbing' do
      before do
        stub_auth_token
      end

      describe 'when other unwanted data exist' do
        it 'ignores them and picks out the allocated COM even when they are not responsible' do
          stub_get_all_offender_managers(
            nomis_offender_id,
            [
              build(:community_all_offender_managers_datum, isPrisonOffenderManager: true, isResponsibleOfficer: true),
              build(:community_all_offender_managers_datum, forenames: 'F1', surname: 'S1', email: 'E1',
                                                            team_name: 'Team1', ldu_code: 'TestLDU',
                                                            isResponsibleOfficer: false)
            ]
          )
          expect(described_class.get_com(nomis_offender_id)).to eq({ 'name' => 'S1, F1',
                                                                     'email' => 'E1',
                                                                     'ldu_code' => 'TestLDU',
                                                                     'team_name' => 'Team1',
                                                                     'is_unallocated' => false,
                                                                     'is_responsible' => false })
        end
      end

      describe "when responsible officer is unallocated" do
        it 'gets leaves out personal info' do
          stub_get_all_offender_managers(
            nomis_offender_id,
            [
              build(:community_all_offender_managers_datum, forenames: 'XXXX', surname: 'XXXX', email: 'XXXX',
                                                            team_name: 'Team1', ldu_code: 'TestLDU',
                                                            isUnallocated: true,
                                                            isResponsibleOfficer: false)
            ]
          )
          expect(described_class.get_com(nomis_offender_id)).to eq({ 'name' => nil,
                                                                     'email' => nil,
                                                                     'ldu_code' => 'TestLDU',
                                                                     'team_name' => 'Team1',
                                                                     'is_unallocated' => true,
                                                                     'is_responsible' => false })
        end
      end

      describe "when email is missing" do
        it 'returns nil' do
          stub_get_all_offender_managers(nomis_offender_id, [build(:community_all_offender_managers_datum, email: nil)])

          result = nil
          expect { result = described_class.get_com(nomis_offender_id) }.not_to raise_error
          expect(result[:email]).to be_nil
        end
      end
    end
  end

  describe 'get_mappa_details' do
    before do
      allow(HmppsApi::CommunityApi).to receive(:get_offender_mappa_details)
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

    it 'gets short descripton' do
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

  describe '#get_offender_sentences_and_offences' do
    before { stub_request(:get, "https://prison-api-dev.prison.service.justice.gov.uk/api/offender-sentences/booking/12345678/sentenceTerms").to_return(status: 200, body: results.to_json, headers: {}) }

    let(:results) do
      [
        {
          'bookingId' => 12_345_678,
          'caseId' => 98_765_432,
          'sentenceSequence' => 1,
          'lineSeq' => 1,
          'termSequence' => 1,
          'lifeSentence' => true,
          'sentenceType' => "LR_ALP",
          'sentenceTypeDescription' => "Recall from Automatic Life",
          'sentenceTermCode' => "IMP",
          'sentenceStartDate' => "1993-10-21",
          'startDate' => "1993-10-21",
          'years' => nil,
          'months' => nil,
          'days' => nil
        },
        {
          'bookingId' => 12_345_678,
          'caseId' => 98_765_432,
          'sentenceSequence' => 2,
          'lineSeq' => 2,
          'termSequence' => 1,
          'lifeSentence' => false,
          'sentenceType' => "LR_ALP",
          'sentenceTypeDescription' => "Recall from Automatic Life",
          'sentenceTermCode' => "IMP",
          'sentenceStartDate' => "1993-10-21",
          'startDate' => "1993-10-21",
          'years' => nil,
          'months' => nil,
          'days' => nil
        },
      ]
    end

    it 'returns each result as an instance of HmppsApi::OffenderSentenceTerm' do
      offender_sentence_terms = double('offender_sentence_terms')
      allow(HmppsApi::OffenderSentenceTerms).to receive(:from_payload).with(results).and_return(offender_sentence_terms)
      expect(described_class.get_offender_sentences_and_offences(12_345_678)).to eq(offender_sentence_terms)
    end
  end
end
