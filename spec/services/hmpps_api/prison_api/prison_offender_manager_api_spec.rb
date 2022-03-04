require 'rails_helper'

describe HmppsApi::PrisonApi::PrisonOffenderManagerApi do
  it 'gets staff detail', vcr: { cassette_name: 'prison_api/pom_get_staff_detail' } do
    list = described_class.list('LEI')
    response = described_class.staff_detail list.first.staff_id

    expect(response.staff_id).to eq(485_636)
    expect(response.first_name).to eq("JENNY")
    expect(response.last_name).to eq("DUCKETT")
    expect(response.status).to eq("ACTIVE")
  end

  it 'can get an Array of Prison Offender Managers (POMs)',
     vcr: { cassette_name: 'prison_api/pom_api_list_spec'  } do
    response = described_class.list('LEI')

    expect(response).to be_instance_of(Array)
    expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
  end

  it 'can handle no POMs for a prison',
     vcr: { cassette_name: 'prison_api/pom_api_list_spec_none'  } do
    response = described_class.list('WEI')

    expect(response).to be_instance_of(Array)
    expect(response.count).to eq(0)
    expect(response).to all(be_an HmppsApi::PrisonOffenderManager)
  end

  describe '#fetch_email_addresses' do
    it "can get a user's single email address",
       vcr: { cassette_name: 'prison_api/elite2_staff_api_get_email' } do
      response = described_class.fetch_email_addresses(485_637)

      expect(response).to eq(["kath.pobee-norris@digital.justice.gov.uk"])
    end

    it "can get multiple email addresses for a user",
       vcr: { cassette_name: 'prison_api/elite2_staff_api_get_emails' } do
      response = described_class.fetch_email_addresses(485_758)

      expect(response).to eq(["ommiicc@digital.justice.gov.uk", "omic@digital.justice.gov.uk"])
    end

    it "returns an empty list if a staff member doesn't have an email address",
       vcr: { cassette_name: 'prison_api/elite2_staff_api_get_no_emails' } do
      response = described_class.fetch_email_addresses(485_636)

      expect(response).to eq([])
    end
  end
end
