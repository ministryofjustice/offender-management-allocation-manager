require 'rails_helper'

RSpec.describe PushPomToDeliusJob, type: :job, versioning: true do
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:offenderNo) }
  let(:pom) { build(:pom) }

  before do
    stub_auth_token
    stub_community_set_pom(offender)
    stub_pom(pom)
  end

  describe 'when a Primary POM is allocated' do
    let!(:allocation) {
      create(:allocation,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: pom.staffId
      )
    }

    before do
      allow(Nomis::Elite2::CommunityApi).to receive(:set_pom)
    end

    it "pushes the offender's allocated POM to the Community API" do
      described_class.perform_now(offender_no)
      expect(Nomis::Elite2::CommunityApi).to have_received(:set_pom).
        with(offender_no: offender_no,
             prison: allocation.prison,
             forename: pom.firstName,
             surname: pom.lastName
        )
    end
  end

  describe 'when there is no allocation for the offender' do
    before do
      allow(Nomis::Elite2::CommunityApi).to receive(:set_pom)
    end

    it 'does nothing' do
      described_class.perform_now(offender_no)
      expect(Nomis::Elite2::CommunityApi).not_to have_received(:set_pom)
    end
  end
end
