require 'rails_helper'

RSpec.describe DebuggingHelper do
  describe '#agency' do
    context 'it takes the agency code from a movement and returns the appropriate string' do
      it 'displays the full prison name if the agency is within the prison estate' do
        expect(agency("LEI")).to eq "HMP Leeds"
      end

      it "returns 'Location outside the prison estate' if the code is not for a prison" do
        expect(agency("ERGERH")).to eq "Location outside the prison estate"
      end
    end
  end
end