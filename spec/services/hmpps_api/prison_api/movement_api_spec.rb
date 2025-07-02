require 'rails_helper'

describe HmppsApi::PrisonApi::MovementApi do
  describe 'Movements for date' do
    let(:movements) do
      [
        { "offenderNo": "G0595VU", "createDateTime": "2019-02-20T12:17:21.542454", "fromAgency": "SWI", "toAgency": "OUT", "movementType": "REL", "directionCode": "OUT", "movementDate": "2019-02-20", "movementTime": "12:14:01" },
        { "offenderNo": "A5019DY", "createDateTime": "2019-02-20T11:06:06.626913", "fromAgency": "DTI", "toAgency": "OUT", "movementType": "REL", "directionCode": "OUT", "movementDate": "2019-02-20", "movementTime": "11:03:46" },
      ]
    end

    before do
      stub_request(:get, "#{ApiHelper::T3}/movements?fromDateTime=2018-02-20T00:00&movementDate=2019-02-20")
        .to_return(body: movements.to_json)
    end

    it 'can get movements on a specific date' do
      movements = described_class.movements_on_date(Date.iso8601('2019-02-20'))

      expect(movements).to be_a(Array)
      expect(movements.length).to eq(2)
      expect(movements).to all be_a(HmppsApi::Movement)
    end
  end

  describe 'Movements for single offenders' do
    let(:prison) { build(:prison) }

    it 'sort movements (oldest first) for a specific_offender' do
      allow_any_instance_of(HmppsApi::Client).to receive(:post).and_return([
        attributes_for(:movement, offenderNo: '2', toAgency: build(:prison).code, movementDate: '2017-03-09').stringify_keys,
        attributes_for(:movement, offenderNo: '1', toAgency: prison.code, movementDate: '2015-01-01').stringify_keys
      ])

      timeline = described_class.movements_for('A5019DY')
      expect(timeline.prison_episode(Date.new 2016, 1, 23).prison_code).to eq(prison.code)
    end
  end
end
