require 'rails_helper'

describe Nomis::Elite2::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  it "can get a list of offenders", vcr: { cassette_name: :get_elite2_offender_list }  do
    response = described_class.get_offender_list('LEI')
    expect(response).not_to be_nil
    expect(response.data).to be_instance_of(Array)
    expect(response.data.first).to be_instance_of(Nomis::OffenderShort)
  end

  it "can get a list of release dates", vcr: { cassette_name: :get_elite2_release_dates }  do
    response = described_class.get_bulk_release_dates(%w[G4273GI G7806VO G2911GD])

    expect(response.data).to be_instance_of(Hash)
    expect(response.data.values.length).to eq(3)
    expect(response.data['G4273GI']).to eq('2020-02-07')
    expect(response.data['G7806VO']).to eq('2017-11-16')
    expect(response.data['G3716UD']).to be_nil
  end

  it "can get a single release date", vcr: { cassette_name: :get_elite2_release_date }  do
    response = described_class.get_bulk_release_dates(['G4273GI'])

    expect(response.data).to be_instance_of(Hash)
    expect(response.data.values.length).to eq(1)
    expect(response.data['G4273GI']).to eq('2020-02-07')
  end
end
