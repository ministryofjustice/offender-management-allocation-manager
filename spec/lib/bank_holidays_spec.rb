describe BankHolidays do
  def bank_holidays_api_will_return(body)
    stub_request(:get, BankHolidays::API_URL).to_return(body: body.to_json)
  end

  before do
    Timecop.travel(Date.parse("01/01/2024"))

    bank_holidays_api_will_return({
      'england-and-wales' => {
        events: [
          { date: "2024-01-01", title: "New Year’s Day" }, # other fields ommitted we don't currently use
          { date: "2024-03-29", title: "Good Friday" },
          { date: "2024-04-01", title: "Easter Monday" }
        ]
      },
      'scotland' => {
        events: [
          { date: "2024-01-01", title: "New Year’s Day" },
          { date: "2024-01-02", title: "2nd January" },
          { date: "2024-03-29", title: "Good Friday" }
        ]
      },
      'northern-ireland' => {
        events: [
          { date: "2024-01-01", title: "New Year’s Day" },
          { date: "2024-03-18", title: "St Patrick’s Day" },
          { date: "2024-03-29", title: "Good Friday" }
        ]
      }
    })
  end

  it 'defaults to england-and-wales results' do
    expect(described_class.dates).to eq(described_class.dates('england-and-wales'))
  end

  it 'returns an array of bank holidays as dates for each given group' do
    expect(described_class.dates('england-and-wales')).to eq(%w[2024-01-01 2024-03-29 2024-04-01].map { Date.parse(it) })
    expect(described_class.dates('scotland')).to eq(%w[2024-01-01 2024-01-02 2024-03-29].map { Date.parse(it) })
    expect(described_class.dates('northern-ireland')).to eq(%w[2024-01-01 2024-03-18 2024-03-29].map { Date.parse(it) })
  end

  it 'caches the response for 1 month' do
    described_class.dates

    bank_holidays_api_will_return({
      'england-and-wales' => { events: [] },
      'scotland' => { events: [] },
      'northern-ireland' => { events: [] }
    })

    expect(described_class.dates('england-and-wales')).to eq(%w[2024-01-01 2024-03-29 2024-04-01].map { Date.parse(it) })
    expect(described_class.dates('scotland')).to eq(%w[2024-01-01 2024-01-02 2024-03-29].map { Date.parse(it) })
    expect(described_class.dates('northern-ireland')).to eq(%w[2024-01-01 2024-03-18 2024-03-29].map { Date.parse(it) })

    Timecop.travel(Date.parse("01/02/2024"))

    expect(described_class.dates('england-and-wales')).to eq([])
    expect(described_class.dates('scotland')).to eq([])
    expect(described_class.dates('northern-ireland')).to eq([])
  end
end
