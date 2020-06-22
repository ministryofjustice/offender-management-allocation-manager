require 'rails_helper'

RSpec.describe CaseloadController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:staff_id) { 456_987 }
  let(:poms) {
    [
      build(:pom,
            firstName: 'Alice',
            position: RecommendationService::PRISON_POM,
            staffId: staff_id
      )
    ]
  }

  before do
    stub_poms(prison, poms)
    stub_sso_pom_data(prison, 'alice')
    stub_signed_in_pom(staff_id, 'alice')
  end

  describe '#handover_start' do
    let(:today_plus_13_weeks) { Time.zone.today + 13.weeks }
    let(:offender) { attributes_for(:offender) }

    before do
      bookings = [offender].map { |o|
        b = attributes_for(:booking).merge(offenderNo: o.fetch(:offenderNo),
                                           bookingId: o.fetch(:bookingId))
        b.fetch(:sentenceDetail)[:automaticReleaseDate] = today_plus_13_weeks
        b
      }
      stub_offenders_for_prison(prison, [offender], bookings)
      create(:case_information, case_allocation: 'CRC', nomis_offender_id: offender.fetch(:offenderNo))
      create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: staff_id, prison: prison)
    end

    it 'can pull back a CRC offender due for handover' do
      get :handover_start, params: { prison_id: prison }
      expect(response).to be_successful
      expect(assigns(:upcoming_handovers).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
    end
  end

  describe '#index' do
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.today - 1.day }

    let(:offenders) { attributes_for_list(:offender, 3).sort_by { |x| x.fetch(:lastName) } }

    before do
      bookings = offenders.map { |o|
        attributes_for(:booking).merge(offenderNo: o.fetch(:offenderNo),
                                       bookingId: o.fetch(:bookingId))
      }

      stub_offenders_for_prison(prison, offenders, bookings)

      # Allocate all of the offenders to this POM
      offenders.each do |offender|
        create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: staff_id, prison: prison)
      end
    end

    it 'returns the caseload' do
      get :index, params: { prison_id: prison }
      expect(response).to be_successful

      expect(assigns(:allocations).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
    end
  end
end
