RSpec.describe HmppsAudit::Message do
  subject(:message) { described_class.new(**event) }

  before do
    allow(Rails.configuration).to receive(:service_name).and_return('service-name')
  end

  let(:event) do
    {
      what: 'VIEW_PRISONER',
      who: 'test-user',
      subject_type: 'PRISONER_ID',
      subject_id: 'A1234BC',
      correlation_id: 'request-123',
      details: { page: 'prisoner-profile' },
    }
  end

  it 'produces the TypeScript-compatible wire format' do
    travel_to(Time.iso8601('2026-10-21T13:00:00+01:00')) do
      expect(message.to_h).to eq(
        what: 'VIEW_PRISONER',
        who: 'test-user',
        subjectType: 'PRISONER_ID',
        subjectId: 'A1234BC',
        correlationId: 'request-123',
        details: '{"page":"prisoner-profile"}',
        service: 'service-name',
        when: '2026-10-21T12:00:00.000Z',
      )
      expect(JSON.parse(message.to_h.to_json).fetch('details')).to eq('{"page":"prisoner-profile"}')
    end
  end

  it 'omits absent optional fields' do
    without_subject = described_class.new(what: 'LOGIN', who: 'test-user', subject_type: 'NOT_APPLICABLE')

    expect(without_subject.to_h.keys).to contain_exactly(:what, :who, :subjectType, :service, :when)
  end

  it 'preserves empty details as a JSON string' do
    expect(described_class.new(**event.merge(details: {})).to_h.fetch(:details)).to eq('{}')
  end

  it 'captures the timestamp once rather than changing it on serialisation' do
    original_timestamp = message.to_h.fetch(:when)

    travel 1.hour do
      expect(message.to_h.fetch(:when)).to eq(original_timestamp)
    end
  end

  it 'captures details at construction rather than retaining a mutable hash' do
    original_details = message.to_h.fetch(:details)
    event.fetch(:details)[:page] = 'changed'

    expect(message.to_h.fetch(:details)).to eq(original_details)
  end

  it 'returns a fresh hash on serialisation' do
    message.to_h.clear

    expect(message.to_h.fetch(:what)).to eq('VIEW_PRISONER')
  end

  %w[PRISONER_ID CRN SEARCH_TERM USER_ID NOT_APPLICABLE REPORT_ID].each do |subject_type|
    it "accepts #{subject_type} with a subject ID" do
      expect(described_class.new(**event.merge(subject_type:)).to_h.fetch(:subjectType)).to eq(subject_type)
    end
  end

  it 'requires the subject_type keyword' do
    expect { described_class.new(**event.except(:subject_type)) }.to raise_error(ArgumentError, /subject_type/)
  end

  [
    { what: '' },
    { what: ' ' },
    { who: '' },
    { who: ' ' },
    { subject_id: nil },
    { subject_id: '' },
    { subject_id: ' ' },
    { subject_type: 'NOT_APPLICABLE', subject_id: nil },
    { correlation_id: '' },
    { correlation_id: ' ' },
  ].each do |allowed_attributes|
    it "allows attributes permitted by the TypeScript interface: #{allowed_attributes.inspect}" do
      attributes = event.merge(allowed_attributes)
      result = described_class.new(**attributes).to_h

      expect(result.fetch(:what)).to eq(attributes.fetch(:what))
      expect(result.fetch(:who)).to eq(attributes.fetch(:who))
      expect(result[:subjectType]).to eq(attributes[:subject_type])
      expect(result[:subjectId]).to eq(attributes[:subject_id])
      expect(result[:correlationId]).to eq(attributes[:correlation_id])
    end
  end

  [
    [{ what: nil }, /what/],
    [{ what: 123 }, /what/],
    [{ who: nil }, /who/],
    [{ who: 123 }, /who/],
    [{ subject_type: 123 }, /subject_type/],
    [{ subject_type: nil }, /subject_type/],
    [{ subject_type: '' }, /subject_type/],
    [{ subject_type: ' ' }, /subject_type/],
    [{ subject_type: 'CUSTOM_TYPE' }, /subject_type/],
    [{ subject_type: 'FOOBAR' }, /subject_type/],
    [{ subject_id: 123 }, /subject_id/],
    [{ correlation_id: 123 }, /correlation_id/],
    [{ details: [] }, /details/],
    [{ details: false }, /details/],
  ].each do |invalid_attributes, error_message|
    it "rejects invalid attributes #{invalid_attributes.inspect}" do
      expect { described_class.new(**event.merge(invalid_attributes)) }.to raise_error(ArgumentError, error_message)
    end
  end
end
