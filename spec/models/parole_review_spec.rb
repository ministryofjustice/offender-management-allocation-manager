require 'rails_helper'

RSpec.describe ParoleReview, type: :model do
  it 'always belongs to an offender' do
    expect(build(:parole_record).offender).not_to be_nil
  end

  describe '#format_hearing_outcome' do
    it 'correctly reformats the hearing outcome to a UI-friendly state' do
      allow(subject).to receive(:hearing_outcome).and_return('No Parole Board Decision - ABC [*]')
      allow(subject).to receive(:format_hearing_outcome).and_call_original

      expect(subject.__send__(:format_hearing_outcome)).to eq('No Parole Board decision – ABC')
    end
  end
end
