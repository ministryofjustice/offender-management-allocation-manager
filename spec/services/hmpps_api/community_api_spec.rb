# frozen_string_literal: true

require 'rails_helper'

describe HmppsApi::CommunityApi do
  let(:api_host) { Rails.configuration.community_api_host }
  let(:offender_no) { 'A1234BC' }

  before do
    stub_auth_token
  end

  describe '.set_pom' do
    let(:stub_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/prisonOffenderManager" }

    before do
      stub_request(:put, stub_url).to_return(status: 200, body: '{}')
    end

    it 'sets the POM name for the given offender' do
      described_class.set_pom(
        offender_no: offender_no,
        prison: 'PVI',
        forename: 'Jane',
        surname: 'Doe'
      )

      expect_body = {
        nomsPrisonInstitutionCode: 'PVI',
        officer: {
          forenames: 'Jane',
          surname: 'Doe'
        }
      }

      expect(WebMock).to have_requested(:put, stub_url)
        .with(
          headers: { 'Content-Type': 'application/json' },
          body: expect_body.to_json
        )
    end
  end

  describe '.unset_pom' do
    describe 'when pom name is nil' do
      let(:stub_url) { "#{api_host}/secure/offenders/nomsNumber/#{offender_no}/prisonOffenderManager" }

      before do
        stub_request(:delete, stub_url).to_return(status: 200)
      end

      it 'deletes the POM name for the given offender' do
        described_class.unset_pom(offender_no)

        expect(WebMock).to have_requested(:delete, stub_url)
      end
    end
  end
end
