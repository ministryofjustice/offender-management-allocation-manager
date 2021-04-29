require 'rails_helper'

RSpec.describe HmppsApi::OffenderCategory, type: :model do
  it 'falls back to asssessmentDate' do
    expect(build(:offender_category, :without_approval_date).active_since).to eq 5.days.ago.to_date
  end
end
