require 'rails_helper'

describe Allocation::Api do
  # Ensure that we have a new instance to prevent other specs interfering
  around do |ex|
    Singleton.__init__(described_class)
    ex.run
    Singleton.__init__(described_class)
  end

  describe 'Application health' do
    it 'fetches the api status' do
      allow_any_instance_of(Allocation::Client).to receive(:get).and_return(
        status: 'ok',
        postgresVersion: 'PostgreSQL 10.3'
      )

      response = described_class.status

      expect(response[:status]).to eq "ok"
      expect(response[:postgresVersion]).to include("PostgreSQL 10.3")
    end
  end

  describe 'Allocation' do
    it 'gets a list allocation records for a POMs' do
      first_staff_id = '1234567'
      second_staff_id = '1234568'
      third_staff_id = '1234569'

      records = described_class.get_allocation_data([
        first_staff_id,
        second_staff_id,
        third_staff_id
      ])

      expect(records.length).to be(3)
      expect(records.values).to all(be_an Allocation::FakeAllocationRecord)
    end

    it 'allocates a POM to an Offender' do
      #TODO - use real api call when ready
      allow_any_instance_of(Allocation::Client).to receive(:post).and_return(
        status: {
          code: 200
        }
      )

      params =   {
        'staff_no' => '1234567',
        'offender_no' => 'A1234AB',
        'offender_id' => '65677888',
        'prison' => 'Leeds',
        'reason' => 'Why not?',
        'notes' =>'Blah',
        'email' => 'pom@pompom.com'
      }

      response = described_class.allocate(params)

      expect(response[:status][:code]).to eq(200)
    end
  end
end
