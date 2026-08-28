require 'rails_helper'

RSpec.describe ParoleReview, type: :model do
  it 'always belongs to an offender' do
    expect(build(:parole_review).offender).not_to be_nil
  end

  describe '#hearing_outcome_as_current' do
    context 'when the hearing outcome is present' do
      it 'returns that outcome' do
        allow(subject).to receive(:hearing_outcome).and_return('Everything OK')
        expect(subject.hearing_outcome_as_current).to eq('Everything OK')
      end
    end

    it 'returns No hearing outcome yet' do
      allow(subject).to receive(:hearing_outcome).and_return(nil)
      expect(subject.hearing_outcome_as_current).to eq('No hearing outcome yet')
    end
  end

  describe '#hearing_outcome_as_historic' do
    context 'when the hearing outcome is present' do
      it 'returns that outcome' do
        allow(subject).to receive(:hearing_outcome).and_return('Everything OK')
        expect(subject.hearing_outcome_as_historic).to eq('Everything OK')
      end
    end

    it 'returns Refused' do
      allow(subject).to receive(:hearing_outcome).and_return(nil)
      expect(subject.hearing_outcome_as_historic).to eq('Refused')
    end
  end

  describe '#formatted_hearing_outcome' do
    it 'correctly reformats the hearing outcome to a UI-friendly state' do
      allow(subject).to receive(:hearing_outcome).and_return('No Parole Board Decision - ABC [*]')
      expect(subject.formatted_hearing_outcome).to eq('No Parole Board decision – ABC')
    end

    it 'returns nil if the hearing outcome is nil' do
      allow(subject).to receive(:hearing_outcome).and_return(nil)
      expect(subject.formatted_hearing_outcome).to be_nil
    end

    it 'returns nil if the hearing outcome is empty' do
      allow(subject).to receive(:hearing_outcome).and_return('')
      expect(subject.formatted_hearing_outcome).to be_nil
    end
  end

  describe '.for_sentences_starting' do
    describe 'it returns a parole review' do
      specify 'when the THD is the same as or after the provided sentence start date' do
        _parole_review_1 = create(:parole_review, target_hearing_date: Date.parse("01/01/2024"))
        parole_review_2 = create(:parole_review, target_hearing_date: Date.parse("01/01/2025"))
        parole_review_3 = create(:parole_review, target_hearing_date: Date.parse("01/01/2026"))

        expect(described_class.for_sentences_starting(Date.parse("01/01/2025"))).to match_array([parole_review_2, parole_review_3])
      end
    end
  end

  describe '.current' do
    describe 'it returns parole reviews' do
      specify 'that have a hearing_outcome_received_on later than 14 days ago' do
        _parole_review_1 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 15.days.ago)
        parole_review_2 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 13.days.ago)
        parole_review_3 = create(:parole_review, review_status: "Not Active",  hearing_outcome_received_on: 1.week.from_now)

        expect(described_class.current).to match_array([parole_review_2, parole_review_3])
      end

      specify 'with no hearing outcome and the review status is active' do
        parole_review_1 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: 'Active - Future')
        parole_review_2 = create(:parole_review, hearing_outcome: nil, review_status: 'Active')
        _parole_review_3 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: "Not Active")

        expect(described_class.current).to match_array([parole_review_1, parole_review_2])
      end
    end
  end

  describe '.previous' do
    describe 'it returns parole reviews' do
      specify 'that have a hearing_outcome_received_on earlier than 14 days ago' do
        parole_review_1 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 15.days.ago)
        _parole_review_2 = create(:parole_review, review_status: "Not Active", hearing_outcome_received_on: 13.days.ago)
        _parole_review_3 = create(:parole_review, review_status: "Not Active",  hearing_outcome_received_on: 1.week.from_now)

        expect(described_class.previous).to match_array([parole_review_1])
      end

      specify 'that have no hearing outcome and are not active' do
        _parole_review_1 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: 'Active - Future')
        _parole_review_2 = create(:parole_review, hearing_outcome: nil, review_status: 'Active')
        parole_review_3 = create(:parole_review, hearing_outcome: 'Not Applicable', review_status: "Not Active")

        expect(described_class.previous).to match_array([parole_review_3])
      end
    end
  end

  describe 'validations on manual update' do
    it 'validates that the hearing_outcome_received_on is in the past' do
      subject.hearing_outcome_received_on = 1.week.from_now
      subject.valid?(:manual_update)
      expect(subject.errors.details[:hearing_outcome_received_on]).to include(error: :in_future)
    end

    it 'validates that the hearing_outcome_received_on is present' do
      subject.hearing_outcome_received_on = nil
      subject.valid?(:manual_update)
      expect(subject.errors.details[:hearing_outcome_received_on]).to include(error: :blank)
    end

    it 'validates that the hearing_outcome_received_on is not older than 10 years' do
      subject.hearing_outcome_received_on = 10.years.ago.to_date - 1.day
      subject.valid?(:manual_update)
      expect(subject.errors.details[:hearing_outcome_received_on]).to include(error: :too_old)
    end

    it 'allows a hearing_outcome_received_on within the last 10 years' do
      subject.hearing_outcome_received_on = 10.years.ago.to_date
      subject.valid?(:manual_update)

      expect(subject.errors[:hearing_outcome_received_on]).to be_empty
    end

    it 'rejects invalid multipart dates that would otherwise roll over' do
      subject.assign_attributes(
        'hearing_outcome_received_on(1i)' => '2020',
        'hearing_outcome_received_on(2i)' => '2',
        'hearing_outcome_received_on(3i)' => '31',
      )

      subject.valid?(:manual_update)

      expect(subject.errors.details[:hearing_outcome_received_on]).to include(error: :invalid)
    end
  end

  describe 'auditing' do
    let!(:parole_review) { create(:parole_review, :pom_task) }

    it 'does not publish an audit event when whodunnit is blank (date update)' do
      PaperTrail.request(whodunnit: nil) do
        expect {
          parole_review.update!(hearing_outcome_received_on: Time.zone.today - 1.day)
        }.not_to change(AuditEvent, :count)
      end
    end

    it 'does not publish an audit event when whodunnit is blank (non-date update)' do
      PaperTrail.request(whodunnit: nil) do
        expect {
          parole_review.update!(review_status: 'Inactive')
        }.not_to change(AuditEvent, :count)
      end
    end

    it 'publishes an audit event for manual date updates' do
      PaperTrail.request(whodunnit: 'MOIC_POM') do
        expect {
          parole_review.assign_attributes(hearing_outcome_received_on: Time.zone.today - 1.day)
          parole_review.save!(context: :manual_update)
        }.to change(AuditEvent, :count).by(1)
      end

      audit = AuditEvent.order(:created_at).last

      aggregate_failures do
        expect(audit.tags).to include('record', 'parole_review', 'changed')
        expect(audit.data['review_id']).to eq(parole_review.review_id)
        expect(audit.data['review_type']).to eq(parole_review.review_type)
        expect(audit.data['review_status']).to eq(parole_review.review_status)
        expect(audit.data['hearing_outcome']).to eq(parole_review.hearing_outcome)
        expect(audit.data['before']).to include('hearing_outcome_received_on' => nil)
        expect(audit.data['after']).to include('hearing_outcome_received_on' => (Time.zone.today - 1.day).to_s)
      end
    end

    it 'publishes an audit event when another user-triggered field changes' do
      PaperTrail.request(whodunnit: 'MOIC_POM') do
        expect {
          parole_review.update!(review_status: 'Inactive')
        }.to change(AuditEvent, :count).by(1)
      end

      audit = AuditEvent.order(:created_at).last

      aggregate_failures do
        expect(audit.tags).to include('record', 'parole_review', 'changed')
        expect(audit.data['before']).to include('review_status' => 'Active')
        expect(audit.data['after']).to include('review_status' => 'Inactive')
      end
    end

    it 'does not publish an audit event on destroy' do
      PaperTrail.request(whodunnit: 'MOIC_POM') do
        expect {
          parole_review.destroy!
        }.not_to change(AuditEvent, :count)
      end
    end
  end
end
