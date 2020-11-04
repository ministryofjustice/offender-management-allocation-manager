require 'rails_helper'

describe OffenderService do
  describe '#get_offender' do
    it "gets a single offender", vcr: { cassette_name: :offender_service_single_offender_spec } do
      nomis_offender_id = 'G4273GI'

      create(:case_information, nomis_offender_id: nomis_offender_id, tier: 'C', case_allocation: 'CRC', welsh_offender: 'Yes')
      offender = described_class.get_offender(nomis_offender_id)

      expect(offender).to be_kind_of(HmppsApi::OffenderBase)
      expect(offender.tier).to eq 'C'
      expect(offender.sentence.conditional_release_date).to eq(Date.new(2020, 3, 16))
      expect(offender.main_offence).to eq 'Section 18 - wounding with intent to resist / prevent arrest'
      expect(offender.case_allocation).to eq 'CRC'
    end

    it "returns nil if offender record not found", vcr: { cassette_name: :offender_service_single_offender_not_found_spec } do
      nomis_offender_id = 'AAA121212CV4G4GGVV'

      offender = described_class.get_offender(nomis_offender_id)
      expect(offender).to be_nil
    end
  end

  describe '#get_community_data' do
    let(:nomis_offender_id) { 'G0239GU' }

    context 'when hitting API', :cluster_vpn, vcr: { cassette_name: :delius_get_community_data } do
      it 'gets some data' do
        expect(described_class.get_community_data(nomis_offender_id)).
            to eq(crn: "X362207",
                  ldu_code: "N07NPSA",
                  mappa_levels: [2],
                  noms_no: "G0239GU",
                  offender_manager: nil,
                  service_provider: "NPS",
                  team_code: "N07UAT",
                  tier: "A")
      end
    end

    context 'with stubbing' do
      before do
        stub_auth_token
      end

      context 'without MAPPA data' do
        before do
          stub_community_registrations(nomis_offender_id, [])
        end

        describe '#service_provider' do
          context 'when NPS' do
            before do
              stub_community_offender(nomis_offender_id,
                                      build(:community_data,
                                            offenderManagers: [
                                                build(:community_offender_manager, probationArea: { nps: true })
                                            ]))
            end

            it 'gets NPS' do
              expect(described_class.get_community_data(nomis_offender_id).fetch(:service_provider)).to eq('NPS')
            end
          end

          context 'when CRC' do
            before do
              stub_community_offender(nomis_offender_id,
                                      build(:community_data,
                                            offenderManagers: [
                                                build(:community_offender_manager, probationArea: { nps: false })
                                            ]))
            end

            it 'gets CRC' do
              expect(described_class.get_community_data(nomis_offender_id).fetch(:service_provider)).to eq('CRC')
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
          stub_community_offender(nomis_offender_id, build(:community_data,
                                                           currentTier: 'A',
                                                           otherIds: { crn: 'X5657657' },
                                                           offenderManagers: [{
                                                                                  team: { code: 'N07GHGF', localDeliveryUnit: { code: 'LDU123' } },
                                                                                  probationArea: { nps: true },
                                                                                  active: true, staff: { unallocated: true } }]))
        end

        context 'with an inactive registration' do
          before do
            stub_community_registrations(nomis_offender_id, [build(:community_registration, active: false)])
          end

          it 'gets some data' do
            expect(described_class.get_community_data(nomis_offender_id))
                .to eq(noms_no: nomis_offender_id, tier: 'A', crn: 'X5657657', offender_manager: nil, service_provider: 'NPS', mappa_levels: [], team_code: 'N07GHGF', ldu_code: 'LDU123')
          end
        end

        context 'with an active non-MAPPA registration' do
          before do
            stub_community_registrations(nomis_offender_id, [build(:community_registration, registerLevel: { code: 'H1' })])
          end

          it 'gets empty mappa levels' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:mappa_levels))
                .to eq([])
          end
        end

        context 'with an active MAPPA registration' do
          before do
            stub_community_registrations(nomis_offender_id, [build(:community_registration, registerLevel: { code: 'M2' })])
          end

          it 'gets mappa_levels' do
            expect(described_class.get_community_data(nomis_offender_id).fetch(:mappa_levels))
                .to eq([2])
          end
        end
      end
    end
  end

  describe "#set_allocated_pom_name" do
    let(:offenders) { Prison.new('LEI').offenders.first(3) }
    let(:nomis_staff_id) { 485_926 }

    before do
      PomDetail.create!(nomis_staff_id: nomis_staff_id, working_pattern: 1.0, status: 'active')
    end

    it "gets the POM names for allocated offenders",
       vcr: { cassette_name: :offender_service_pom_names_spec } do
      allocate_offender(DateTime.now.utc)

      updated_offenders = described_class.set_allocated_pom_name(offenders, 'LEI')
      expect(updated_offenders).to be_kind_of(Array)
      expect(updated_offenders.first).to be_kind_of(HmppsApi::OffenderSummary)
      expect(updated_offenders.count).to eq(offenders.count)
      expect(updated_offenders.first.allocated_pom_name).to eq('Pom, Moic')
      expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
    end

    it "uses 'updated_at' date when 'primary_pom_allocated_at' date is nil",
       vcr: { cassette_name: :offender_service_set_allocated_pom_when_primary_pom_date_nil } do
      allocate_offender(nil)

      updated_offenders = described_class.set_allocated_pom_name(offenders, 'LEI')
      expect(updated_offenders.first.allocated_pom_name).to eq('Pom, Moic')
      expect(updated_offenders.first.allocation_date).to be_kind_of(Date)
    end
  end

  def allocate_offender(allocated_date)
    Allocation.create!(
      nomis_offender_id: offenders.first.offender_no,
      nomis_booking_id: 1_153_753,
      prison: 'LEI',
      allocated_at_tier: 'C',
      created_by_username: 'MOIC_POM',
      primary_pom_nomis_id: nomis_staff_id,
      primary_pom_allocated_at: allocated_date,
      recommended_pom_type: 'prison',
      event: Allocation::ALLOCATE_PRIMARY_POM,
      event_trigger: Allocation::USER
    )
  end
end
