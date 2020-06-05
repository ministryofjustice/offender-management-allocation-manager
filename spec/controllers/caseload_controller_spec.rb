require 'rails_helper'

RSpec.describe CaseloadController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:poms) {
    [
      build(:pom,
            firstName: 'Alice',
            position: RecommendationService::PRISON_POM)
    ]
  }
  let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }
  let(:offender) { attributes_for(:offender) }

  before do
    stub_poms(prison, poms)
    stub_sso_pom_data(prison, 'alice')
    stub_signed_in_pom(poms.first.staffId, 'alice')

    bookings = [offender].map { |o|
      b = attributes_for(:booking).merge(offenderNo: o.fetch(:offenderNo),
                                     bookingId: o.fetch(:bookingId))
      b.fetch(:sentenceDetail)[:automaticReleaseDate] = today_plus_13_weeks
      b
    }
    stub_offenders_for_prison(prison, [offender], bookings)
    create(:case_information, case_allocation: 'CRC', nomis_offender_id: offender.fetch(:offenderNo))
    create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: poms.first.staffId, prison: prison)
  end

  describe '#handover_start' do
    it 'can pull back a CRC offender due for handover' do
      get :handover_start, params: { prison_id: prison }
      expect(response).to be_successful
      expect(assigns(:upcoming_handovers).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
    end
  end
end
