# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseloadHelper do
  describe '#prisoner_location' do
    context 'with latest_temp_movement_date method (allocated offender)' do
      it 'displays the date of temporary movement if ROTL exists' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: Time.zone.today, location: "Z-10-112", restricted_patient?: false)
        expect(helper.prisoner_location(offender)).to eq "Temporary absence<br />(out #{Time.zone.today.to_fs(:rfc822)})"
      end

      it 'displays the location of the cell if no there is no ROTL' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, location: "Z-10-112", restricted_patient?: false)
        expect(helper.prisoner_location(offender)).to eq "Z-10-112"
      end

      it 'displays N/A if there is no ROTL or cell location' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, location: nil, restricted_patient?: false)
        expect(helper.prisoner_location(offender)).to eq "N/A"
      end

      it 'displays unknown if there is no hospital location for restricted patient' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, location: nil, restricted_patient?: true)
        expect(helper.prisoner_location(offender)).to eq "This person is being held<br />under the Mental Health Act<br />at Unknown"
      end

      it 'displays full hospital location for restricted patient' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, location: "Heartlands", restricted_patient?: true)
        expect(helper.prisoner_location(offender)).to eq "This person is being held<br />under the Mental Health Act<br />at Heartlands"
      end

      it 'displays hospital location only for restricted patient' do
        offender = OpenStruct.new(offender_no: 'G4706UP', latest_temp_movement_date: nil, location: "Heartlands", restricted_patient?: true)
        expect(helper.prisoner_location(offender, location_only: true)).to eq "Heartlands"
      end
    end
  end
end
