require 'rails_helper'

RSpec.describe PushPomToDeliusJob, type: :job, versioning: true do
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:pom) { build(:pom) }

  before do
    stub_auth_token
    stub_pom(pom)
  end

  describe 'when a Primary POM is allocated', :disable_allocation_change_publish do
    let!(:allocation) do
      create(:allocation_history,
             prison: build(:prison).code,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: pom.staffId
            )
    end

    before do
      allow(HmppsApi::CommunityApi).to receive(:set_pom)
    end

    it "pushes the offender's allocated POM to the Community API" do
      described_class.perform_now(allocation)
      expect(HmppsApi::CommunityApi).to have_received(:set_pom)
          .with(offender_no: offender_no,
                prison: allocation.prison,
                forename: pom.firstName,
                surname: pom.lastName
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
    end

    it "pushes the unset offender's POM to the Community API" do
      described_class.perform_now(allocation)
      expect(HmppsApi::CommunityApi).to have_received(:unset_pom)
          .with(offender_no)
    end
  end
end
