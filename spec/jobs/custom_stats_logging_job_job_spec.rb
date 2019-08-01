require 'rails_helper'

RSpec.describe CustomStatsLoggingJob, type: :job do
  before do
    create(:case_information)
  end

  it 'does not crash' do
    described_class.perform_now
  end
end
