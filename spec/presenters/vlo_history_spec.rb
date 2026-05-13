require 'rails_helper'

RSpec.describe VloHistory do
  let(:event) { 'create' }
  let(:version) { PaperTrail::Version.new(event:) }
  let(:presenter) { described_class.new(version) }
  let(:expected_partial_path) { 'case_history/vlo/create' }

  it_behaves_like 'a paper trail timeline presenter'
end
