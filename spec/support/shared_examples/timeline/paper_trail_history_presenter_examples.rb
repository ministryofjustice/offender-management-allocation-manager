RSpec.shared_examples 'a paper trail timeline presenter' do
  it 'returns the expected partial path' do
    expect(presenter.to_partial_path).to eq(expected_partial_path)
  end

  it 'uses the stored PaperTrail user names when available' do
    version = PaperTrail::Version.new(event: event, user_first_name: 'Joe', user_last_name: 'Bloggs', whodunnit: 'jbloggs')

    expect(described_class.new(version).created_by_name).to eq('Joe Bloggs')
  end

  it 'falls back to whodunnit when PaperTrail user names are missing' do
    version = PaperTrail::Version.new(event: event, whodunnit: 'jbloggs')

    expect(described_class.new(version).created_by_name).to eq('jbloggs')
  end
end
