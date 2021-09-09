require 'rails_helper'

RSpec.describe DebuggingHelper do
  describe '#agency' do
    context 'when parsing an agency code from a movement it returns the appropriate string' do
      it 'displays the full prison name if the agency is within the prison estate' do
        expect(agency("LEI")).to eq "Leeds (HMP)"
      end

      it "returns 'Location outside the prison estate' if the code is not for a prison" do
        expect(agency("ERGERH")).to eq "Location outside the prison estate"
      end
    end
  end
end
