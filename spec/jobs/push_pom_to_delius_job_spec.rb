require 'rails_helper'

RSpec.describe PushPomToDeliusJob, type: :job, versioning: true do
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:pom) { build(:pom) }

  before do
    stub_auth_token
    stub_pom(pom)
    allow(AuditEvent).to receive(:publish)
  end

  describe 'when a Primary POM is allocated' do
    let!(:allocation) do
      create(:allocation_history,
             prison: build(:prison).code,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: pom.staffId
            )
    end

    before do
      allow(HmppsApi::CommunityApi).to receive(:set_pom)
      described_class.perform_now(allocation)
    end

    it "pushes the offender's allocated POM to the Community API" do
      expect(HmppsApi::CommunityApi).to have_received(:set_pom)
          .with(offender_no: offender_no,
                prison: allocation.prison,
                forename: pom.firstName,
                surname: pom.lastName
               )
    end

    it 'publishes an audit event' do
      expect(AuditEvent).to have_received(:publish)
          .with(nomis_offender_id: offender_no,
                tags: %w[job push_pom_to_delius_job allocation changed],
                system_event: true,
                data: {
                  'prison' => allocation.prison,
                  'forename' => pom.firstName,
                  'surname' => pom.lastName
                }
               )
    end
  end

  describe 'when a Primary POM is de-allocated' do
    let!(:allocation) do
      create(:allocation_history, :transfer,
             prison: build(:prison).code,
             nomis_offender_id: offender_no
      )
    end

    before do
      allow(HmppsApi::CommunityApi).to receive(:unset_pom)
      described_class.perform_now(allocation)
    end

    it "pushes the unset offender's POM to the Community API" do
      expect(HmppsApi::CommunityApi).to have_received(:unset_pom)
          .with(offender_no)
    end

    it 'publishes an audit event' do
      expect(AuditEvent).to have_received(:publish)
          .with(nomis_offender_id: offender_no,
                tags: %w[job push_pom_to_delius_job allocation removed],
                system_event: true,
                data: {}
               )
    end
  end
end
