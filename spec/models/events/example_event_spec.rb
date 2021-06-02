require 'rails_helper'
require 'models/events/offender_event_shared'

# An example type of offender event
# Each type of event should be represented by its own class, extending Events::OffenderEvent
module Events
  class ExampleEvent < OffenderEvent
    # Define fields to be stored in the JSONB field "metadata"
    jsonb_accessor :metadata,
                   name: :string,
                   date_of_birth: :date,
                   language: :string

    validates :name, presence: true
    validates :language, inclusion: { in: %w[ruby javascript php] }
    validates :date_of_birth, presence: true
    validate :aged_over_18

    def aged_over_18
      if date_of_birth.present? && date_of_birth > 18.years.ago
        errors.add(:date_of_birth, "must be over 18 years old")
      end
    end
  end
end

RSpec.describe Events::ExampleEvent, type: :model do
  # Subject is a valid ExampleEvent object
  subject {
    described_class.new(
      # core fields for OffenderEvent:
      nomis_offender_id: 'ABC123',
      triggered_by: :system,
      happened_at: Time.zone.now,
      # metadata fields for ExampleEvent:
      name: name,
      date_of_birth: date_of_birth,
      language: language
    )
  }

  # Valid metadata fields
  let(:name) { Faker::Name.name }
  let(:date_of_birth) { Faker::Date.birthday(min_age: 18, max_age: 99) }
  let(:language) { 'ruby' }

  it_behaves_like "an OffenderEvent"

  describe 'metadata validation' do
    context 'with the expected metadata fields' do
      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'with invalid metadata fields' do
      # name is empty
      let(:name) { nil }

      # younger than 18 years
      let(:date_of_birth) { Faker::Date.birthday(min_age: 1, max_age: 17) }

      # not in the list of valid languages
      let(:language) { 'perl' }

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.to_h).to eq("name": "can't be blank",
                                          "date_of_birth": 'must be over 18 years old',
                                          "language": 'is not included in the list')
      end
    end

    context 'with nil metadata' do
      let(:name) { nil }
      let(:date_of_birth) { nil }
      let(:language) { nil }

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.to_h).to eq("name": "can't be blank",
                                          "date_of_birth": "can't be blank",
                                          "language": 'is not included in the list')
      end
    end
  end

  context 'when loaded from the database' do
    before do
      subject.save!
    end

    it 'casts dates to Date objects' do
      # Load the record fresh from the database
      event = described_class.first

      expect(event.date_of_birth).to be_a(Date)
      expect(event.happened_at).to be_a(Time)
    end
  end
end
