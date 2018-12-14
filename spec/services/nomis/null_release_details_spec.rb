require "rails_helper"

RSpec.describe Nomis::NullReleaseDetails do
  it { expect(subject.release_date).to eq(nil) }
end
