require 'rails_helper'

RSpec.describe Api::AllocationApiController, :allocation, type: :controller do
  describe '#show' do
    let(:rsa_private) { OpenSSL::PKey::RSA.generate 2048 }
    let(:prison) { create(:prison) }
    let!(:co_working_allocation) {
      create(:allocation_history, :co_working, primary_pom_nomis_id: primary_pom.staff_id,
                                          secondary_pom_nomis_id: secondary_pom.staff_id, nomis_offender_id: offender.fetch(:offenderNo))
    }
    let(:primary_pom) { build(:pom) }
    let(:secondary_pom) { build(:pom) }

    let(:rsa_public) { Base64.strict_encode64(rsa_private.public_key.to_s) }

    before do
      allow(Rails.configuration).to receive(:nomis_oauth_public_key).and_return(rsa_public)
      accepts_bearer_tokens
      stub_pom(primary_pom)
      stub_pom(secondary_pom)
      stub_offender(offender)
      stub_auth_token
    end


    describe 'when a pom has been allocated an offender' do
      context 'when an offender is currently serving a sentence' do
        let(:offender) { build(:nomis_offender, agencyId: prison.code,  sentence: attributes_for(:sentence_detail)) }

        it 'returns pom allocation details' do
          get :show, params: { prison_id: prison.code, offender_no: offender.fetch(:offenderNo) }

          expect(response).to have_http_status(200)
          expect(JSON.parse(response.body)).to eq("primary_pom" => { "name" => primary_pom.full_name.to_s, "staff_id" => primary_pom.staff_id },
                                                  "secondary_pom" => {  "name" => secondary_pom.full_name.to_s, "staff_id" => secondary_pom.staff_id })
        end
      end

      context 'when an offender has finished their sentence' do
        # currently an offender is not able to be unallocated from a pom. As a result the the pom remains on the DPS
        # quick look screen once an offenders sentence has finished. This is a quick fix to stop this happening.
        let(:offender) { build(:nomis_offender, agencyId: prison.code,  sentence: attributes_for(:sentence_detail, :unsentenced)) }

        it 'does not return a poms allocation details' do
          create(:allocation_history, prison: prison.code, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: primary_pom.staffId, secondary_pom_nomis_id: secondary_pom.staffId)
          get :show, params: { prison_id: prison.code, offender_no: offender.fetch(:offenderNo) }

          expect(response).to have_http_status(404)
          expect(JSON.parse(response.body)).to eq("message" => "Not allocated", "status" => "error")
        end
      end
    end
  end

  def accepts_bearer_tokens
    payload = {
      user_name: 'Sally600',
      scope: ['read'],
      exp: 4.hours.from_now.to_i
    }
    request_header(payload)
  end

  def encode_payload(payload)
    JWT.encode(payload, OpenSSL::PKey::RSA.new(rsa_private), 'RS256')
  end

  def request_header(payload)
    token = encode_payload(payload)
    request.headers['AUTHORIZATION'] = "Bearer #{token}"
  end
end
