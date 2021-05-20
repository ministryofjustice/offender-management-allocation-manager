require 'rails_helper'

RSpec.describe HmppsApi::PrisonTimeline, type: :model do
  let(:p1) { build(:prison).code }
  let(:p2) { build(:prison).code }
  let(:p3) { build(:prison).code }
  let(:p4) { build(:prison).code }
  let(:unknown_code) { 'XYZ' }

  let(:model) {
    described_class.new([
                          build(:movement, movementDate: one_month_ago, toAgency: p1),
                          build(:movement, movementDate: last_fortnight, toAgency: p2),
                          build(:movement, movementDate: last_week, toAgency: p3),
                          build(:movement, :transfer, :out, movementDate: three_days_ago, toAgency: p4),
                          build(:movement, :transfer, movementDate: today, toAgency: unknown_code),
                        ])
  }
  let(:tomorrow) { Time.zone.today + 1.day }
  let(:today) { Time.zone.today }
  let(:last_fortnight) { Time.zone.today - 14.days }
  let(:two_weeks_ago) { Time.zone.now - 14.days }
  let(:last_week) { Time.zone.today - 7.days }
  let(:three_days_ago) { Time.zone.today - 3.days }
  let(:one_month_ago) { Time.zone.today - 1.month }

  context 'when today' do
    subject {
      model.prison_episode(today).prison_code
    }

    it 'returns prison code for today' do
      expect(subject).to eq(p3)
    end
  end

  context 'when tomorrow' do
    subject {
      model.prison_episode(tomorrow).prison_code
    }

    it 'returns prison code for tomorrow' do
      expect(subject).to eq(p3)
    end
  end

  context 'when second prison' do
    subject {
      model.prison_episode(two_weeks_ago).prison_code
    }

    it 'returns prison code for last week' do
      expect(subject).to eq(p2)
    end
  end
end
