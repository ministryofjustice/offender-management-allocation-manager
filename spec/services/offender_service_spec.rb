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

      create(:case_information, offender: build(:offender, nomis_offender_id: nomis_offender_id), tier: 'C', case_allocation: 'CRC', probation_service: 'Wales')
      offender = described_class.get_offender(nomis_offender_id)

      expect(offender.tier).to eq 'C'
      expect(offender.conditional_release_date).to eq(Date.new(2040, 1, 27))
      expect(offender.main_offence).to eq 'Robbery'
      expect(offender.case_allocation).to eq 'CRC'
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
            .to eq(crn: "X349420",
                   ldu_code: "N07NPSA",
                   mappa_levels: [],
                   noms_no: nomis_offender_id,
                   offender_manager: "Cheema, Gurnank",
                   service_provider: "NPS",
                   team_name: "OMU A",
                   tier: "B2")
      end
    end

    context 'with stubbing' do
      before do
        stub_auth_token
      end

      context 'without MAPPA data' do
        describe '#service_provider' do
          subject { described_class.get_community_data(nomis_offender_id).fetch(:service_provider) }

          before do
            stub_community_offender(nomis_offender_id, community_data)
          end

          context 'when enhancedResourcing is true' do
            let(:community_data) { build(:community_data, enhancedResourcing: true) }

            it 'is NPS' do
              expect(subject).to eq('NPS')
            end
          end

          context 'when enhancedResourcing is false' do
            let(:community_data) { build(:community_data, enhancedResourcing: false) }

            it 'is CRC' do
              expect(subject).to eq('CRC')
            end
          end

          context 'when not found' do
            # this means that the offender hasn't had a CAS assessment yet
            let(:community_data) { build(:community_data) }

            before do
              stub_resourcing_404 nomis_offender_id
            end

            it 'defaults to NPS' do
              expect(subject).to eq('NPS')
            end
          end

          context 'when enhancedResourcing field is missing' do
            # this typically means that the offender has a draft CAS assessment which hasn't been completed yet
            # and is therefore in a "Not Assessed" state
            let(:community_data) { build(:community_data) }

            before do
              # enhancedResourcing field is missing
              stub_community_offender(nomis_offender_id,
                                      build(:community_data))
            end

            it 'defaults to NPS' do
              expect(subject).to eq('NPS')
            end
          end
        end

        context 'with a single allocated COM' do
          before do
            stub_community_offender(nomis_offender_id, build(:community_data,
                                                             offenderManagers: [{ probationArea: { nps: true }, active: true, staff: { unallocated: false, surname: 'Jones', forenames: 'Ruth Mary' } }]))
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
                                            probationArea: { nps: true },
                                            active: true,
                                            staff: { unallocated: true } }
                                        ]), registrations)
        end

        context 'with an inactive registration' do
          let(:registrations) { [build(:community_registration, active: false)] }

          it 'gets some data' do
            expect(described_class.get_community_data(nomis_offender_id))
                .to eq(noms_no: nomis_offender_id, tier: 'A', crn: 'X5657657',
                       offender_manager: nil, service_provider: 'NPS', mappa_levels: [],
                       team_name: 'Thing', ldu_code: 'LDU123')
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
    end
  end
end
