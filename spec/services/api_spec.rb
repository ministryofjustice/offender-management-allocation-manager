
describe 'testing out vcr', vcr: { cassette_name: :test } do
  it 'works' do
    response = Net::HTTP.get_response(URI('http://www.iana.org/domains/reserved'))
    expect(response.body).to eq('bleh')
  end
end
