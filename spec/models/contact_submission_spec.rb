require 'rails_helper'

RSpec.describe ContactSubmission, type: :model do
  it { described_class.validates_presence_of(:job_type) }
  it { described_class.validates_presence_of(:email_address) }
  it { described_class.validates_presence_of(:name) }
  it { described_class.validates_presence_of(:body) }
  it { described_class.validates_presence_of(:prison) }
end
