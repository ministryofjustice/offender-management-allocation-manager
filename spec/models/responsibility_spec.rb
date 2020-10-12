require 'rails_helper'

RSpec.describe Responsibility, type: :model do
  let(:offender_id) { 'GA1234G' }

  before do
    create(:case_information, nomis_offender_id: offender_id)
  end

  context 'with other reason' do
    subject { build(:responsibility, nomis_offender_id: offender_id, reason: :other_reason) }

    it { is_expected.not_to be_valid }
  end

  context 'with default factory' do
    subject { build(:responsibility, nomis_offender_id: offender_id) }

    it { is_expected.to be_valid }
  end

  context 'with invalid override' do
    subject { build(:responsibility, nomis_offender_id: offender_id, value: 'wibble') }

    it { is_expected.not_to be_valid }
  end

  context 'with prison override' do
    subject { build(:responsibility, nomis_offender_id: offender_id, value: 'Prison') }

    it { is_expected.to be_valid }
  end
end
