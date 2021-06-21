# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseloadHelper do
  describe '#prisoner_location' do
    context 'with latest_temp_movement_date method (allocated offender)' do
      it 'displays the date of temporary movement if ROTL exists' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: Time.zone.today, cell_location: "Z-10-112")
        expect(helper.prisoner_location(offender)).to eq "Temporary absence (out #{Time.zone.today.to_s(:rfc822)})"
      end

      it 'displays the location of the cell if no there is no ROTL' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, cell_location: "Z-10-112")
        expect(helper.prisoner_location(offender)).to eq "Z-10-112"
      end

      it 'displays N/A if there is no ROTL or cell location' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, cell_location: nil)
        expect(helper.prisoner_location(offender)).to eq "N/A"
      end
    end
  end
end
