# frozen_string_literal: true

require 'rails_helper'

RSpec.describe NomisUserRolesService do
  let(:prison) { create(:prison) }
  let(:nomis_staff_id) { 123_456 }
  let(:spo_username) { 'SPO_USER' }
  let(:pom) { build(:pom, staffId: nomis_staff_id) }
  let(:pom_list) { [pom] }

  describe '.search_staff' do
    let(:filter) { 'Smith' }
    let(:api_response) do
      {
        'content' => [
          { 'staffId' => 111 },
          { 'staffId' => 222 },
          { 'staffId' => 333 }
        ],
        'totalElements' => 3
      }
    end

    before do
      allow(HmppsApi::NomisUserRolesApi).to receive(:get_users).and_return(api_response)
      allow(prison).to receive(:get_list_of_poms).and_return([double(staff_id: 222)])
    end

    it 'calls the NOMIS API with correct parameters' do
      described_class.search_staff(prison, filter)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:get_users).with(
        caseload: prison.code, filter: filter
      )
    end

    it 'filters out existing POMs and adjusts total count' do
      results, total = described_class.search_staff(prison, filter)

      expect(results).to contain_exactly({ 'staffId' => 111 }, { 'staffId' => 333 })
      expect(total).to eq(2)
    end

    context 'when a POM has been soft-deleted but still has their NOMIS role' do
      before do
        # POM 333 is soft-deleted locally but their NOMIS role has not yet been
        # expired (e.g. cases still pending reallocation). They should still be
        # excluded from the search results to prevent re-onboarding mid-removal
        allow(prison).to receive(:get_list_of_poms)
          .with(include_deleted: true)
          .and_return([double(staff_id: 222), double(staff_id: 333)])
      end

      it 'excludes the soft-deleted POM from results' do
        results, total = described_class.search_staff(prison, filter)

        expect(results).to contain_exactly({ 'staffId' => 111 })
        expect(total).to eq(1)
      end
    end

    context 'when a POM has been fully removed (role expired in NOMIS)' do
      before do
        # POM 222 was previously removed and their NOMIS role has been expired,
        # so `get_list_of_poms` no longer returns them. They will appear in the
        # search results so they can be re-onboarded
        allow(prison).to receive(:get_list_of_poms)
          .with(include_deleted: true)
          .and_return([])
      end

      it 'includes the fully removed POM in results' do
        results, total = described_class.search_staff(prison, filter)

        expect(results).to contain_exactly(
          { 'staffId' => 111 }, { 'staffId' => 222 }, { 'staffId' => 333 }
        )
        expect(total).to eq(3)
      end
    end

    context 'when API returns empty results' do
      let(:api_response) { {} }

      it 'returns empty array and zero count' do
        results, total = described_class.search_staff(prison, filter)

        expect(results).to be_empty
        expect(total).to eq(0)
      end
    end
  end

  describe '.add_pom' do
    let(:config) { { hours_per_week: 37.5, position: 'PRO', schedule_type: 'FT' } }
    let(:pom_detail) { instance_double(PomDetail) }

    before do
      allow(HmppsApi::NomisUserRolesApi).to receive(:set_staff_role)
      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:expire_list_cache)
      allow(prison.pom_details).to receive(:find_or_initialize_by).with(nomis_staff_id:).and_return(pom_detail)
      allow(pom_detail).to receive(:update!)
    end

    it 'sets the staff role and creates or updates the POM details' do
      described_class.add_pom(prison, nomis_staff_id, spo_username, config)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:set_staff_role).with(
        prison.code, nomis_staff_id, config
      )

      expect(
        HmppsApi::PrisonApi::PrisonOffenderManagerApi
      ).to have_received(:expire_list_cache).with(prison.code)

      expect(prison.pom_details).to have_received(:find_or_initialize_by).with(nomis_staff_id:)
      expect(pom_detail).to have_received(:update!).with(
        created_by: spo_username,
        status: 'active',
        hours_per_week: config[:hours_per_week]
      )
    end

    describe 'audit event on POM onboarding' do
      before do
        PaperTrail.request.whodunnit = spo_username
      end

      after do
        PaperTrail.request.whodunnit = nil
      end

      it 'publishes an audit event with onboarding details' do
        described_class.add_pom(prison, nomis_staff_id, spo_username, config)

        audit_event = AuditEvent.tags('nomis_role', 'created').last
        expect(audit_event).to have_attributes(
          system_event: false,
          username: spo_username,
          tags: %w[nomis_role created],
        )
        expect(audit_event.data).to include(
          'prison_code' => prison.code,
          'staff_id' => nomis_staff_id,
          'position' => 'PRO',
          'schedule_type' => 'FT',
          'hours_per_week' => 37.5,
        )
      end
    end
  end

  describe '.remove_pom' do
    let(:event_trigger) { AllocationHistory::INACTIVE_POM }
    let!(:pom_detail) { create(:pom_detail, :active, prison_code: prison.code, nomis_staff_id: nomis_staff_id) }

    before do
      allow(AllocationHistory).to receive(:deallocate_pom)

      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:list).and_return(pom_list)
      allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:expire_list_cache)
      allow(HmppsApi::NomisUserRolesApi).to receive(:expire_staff_role)
    end

    it 'deallocates both primary and secondary POMs' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(AllocationHistory).to have_received(:deallocate_pom).with(
        nomis_staff_id, prison.code, event_trigger:
      )
    end

    it 'soft-deletes the POM details' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(pom_detail.reload).to be_deleted
    end

    it 'expires the staff role' do
      described_class.remove_pom(prison, nomis_staff_id)

      expect(HmppsApi::NomisUserRolesApi).to have_received(:expire_staff_role).with(pom)

      expect(
        HmppsApi::PrisonApi::PrisonOffenderManagerApi
      ).to have_received(:expire_list_cache).with(prison.code)
    end

    describe 'audit event on role expiry' do
      context 'when triggered by a user' do
        before do
          PaperTrail.request.whodunnit = spo_username
        end

        after do
          PaperTrail.request.whodunnit = nil
        end

        it 'publishes a user-initiated audit event with POM details' do
          described_class.remove_pom(prison, nomis_staff_id)

          audit_event = AuditEvent.tags('nomis_role', 'expired').last
          expect(audit_event).to have_attributes(
            system_event: false,
            username: spo_username,
            tags: %w[nomis_role expired],
          )
          expect(audit_event.data).to include(
            'prison_code' => prison.code,
            'staff_id' => nomis_staff_id,
            'from_date' => pom.from_date,
            'position' => pom.position,
            'schedule_type' => pom.schedule_type,
            'hours_per_week' => pom.hours_per_week,
          )
        end
      end

      context 'when triggered by the system (no whodunnit)' do
        before do
          PaperTrail.request.whodunnit = nil
        end

        it 'publishes a system audit event' do
          described_class.remove_pom(prison, nomis_staff_id)

          audit_event = AuditEvent.tags('nomis_role', 'expired').last
          expect(audit_event).to have_attributes(
            system_event: true,
            username: nil,
          )
        end
      end

      context 'when POM is not found in NOMIS' do
        let(:pom_list) { [] }

        it 'does not publish an audit event' do
          described_class.remove_pom(prison, nomis_staff_id)

          expect(AuditEvent.tags('nomis_role', 'expired')).to be_empty
        end
      end

      context 'when the NOMIS role expiry fails' do
        before do
          allow(HmppsApi::NomisUserRolesApi).to receive(:expire_staff_role)
            .and_raise(Faraday::ServerError, 'the server responded with status 500')
          allow(Rails.logger).to receive(:error)
          allow(Rails.error).to receive(:report)
        end

        it 'does not publish an audit event' do
          described_class.remove_pom(prison, nomis_staff_id)

          expect(AuditEvent.tags('nomis_role', 'expired')).to be_empty
        end
      end
    end

    context 'when POM is not found' do
      let(:pom_list) { [] }

      it 'does not attempt to expire the staff role' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(HmppsApi::NomisUserRolesApi).not_to have_received(:expire_staff_role)
        expect(HmppsApi::PrisonApi::PrisonOffenderManagerApi).not_to have_received(:expire_list_cache)
      end
    end

    context 'when the NOMIS role expiry fails' do
      before do
        allow(HmppsApi::NomisUserRolesApi).to receive(:expire_staff_role)
          .and_raise(Faraday::ServerError, 'the server responded with status 500')
        allow(Rails.logger).to receive(:error)
        allow(Rails.error).to receive(:report)
      end

      it 'still deallocates the POM' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(AllocationHistory).to have_received(:deallocate_pom).with(
          nomis_staff_id, prison.code, event_trigger:
        )
      end

      it 'still soft-deletes the POM details' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(pom_detail.reload).to be_deleted
      end

      it 'logs a structured error event' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(Rails.logger).to have_received(:error).with(
          /event=nomis_role_removal_failed.*staff_id=#{nomis_staff_id}.*from_date=/
        )
      end

      it 'reports to Rails error reporter with context' do
        described_class.remove_pom(prison, nomis_staff_id)

        expect(Rails.error).to have_received(:report).with(
          an_instance_of(Faraday::ServerError),
          severity: :warning,
          source: 'nomis_role_removal',
          context: hash_including(
            prison_id: prison.code,
            staff_id: nomis_staff_id,
            from_date: pom.from_date,
          ),
        )
      end

      it 'does not raise' do
        expect { described_class.remove_pom(prison, nomis_staff_id) }.not_to raise_error
      end
    end
  end
end
