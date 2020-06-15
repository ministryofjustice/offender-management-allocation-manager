require 'rails_helper'

RSpec.describe PomsController, type: :controller do
  let(:prison) { build(:prison) }
  let(:a_offenders) { build_list(:offender, 2) }
  let(:b_offenders) { build_list(:offender, 4) }
  let(:c_offenders) { build_list(:offender, 3) }
  let(:d_offenders) { build_list(:offender, 1) }

  before do
    stub_sso_data(prison.code)
    inactive = create(:pom_detail, :inactive)
    active = create(:pom_detail, :active)
    unavailable = create(:pom_detail, :unavailable)
    stub_poms(prison.code, [
      build(:pom, staffId: inactive.nomis_staff_id),
      build(:pom, staffId: active.nomis_staff_id),
      build(:pom, staffId: unavailable.nomis_staff_id)
    ])
    a1 = create(:case_information, tier: 'A', nomis_offender_id: a_offenders.first.offender_no)
    create(:allocation, nomis_offender_id: a1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    a2 = create(:case_information, tier: 'A', nomis_offender_id: a_offenders.last.offender_no)
    create(:allocation, nomis_offender_id: a2.nomis_offender_id, primary_pom_nomis_id: inactive.nomis_staff_id, secondary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    {
      'B': b_offenders,
      'C': c_offenders,
      'D': d_offenders,
    }.each do |tier, offenders|
      offenders.map(&:offender_no).each do |offender_no|
        create(:case_information, tier: tier.to_s, nomis_offender_id: offender_no)
        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
      end
    end
  end

  render_views

  context 'with an extra unsentenced offender' do
    let(:active_staff_id) { PomDetail.where(status: 'active').first!.nomis_staff_id }
    let(:unavailable_staff_id) { PomDetail.where(status: 'unavailable').first!.nomis_staff_id }
    let(:offenderNos) { (a_offenders + b_offenders + c_offenders + d_offenders).map(&:offender_no) }

    before do
      # This guy doesn't turn up in Prison#offenders, and hence doesn't show up on caseload or stats
      missing_offender = create(:case_information)
      create(:allocation, nomis_offender_id: missing_offender.nomis_offender_id, primary_pom_nomis_id: active_staff_id, prison: prison.code)

      stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/#{active_staff_id}").
        to_return(body: { staffId: active_staff_id, lastName: 'LastName', firstName: 'FirstName' }.to_json)

      offenders = offenderNos.map.with_index { |nomis_id, index|
        { "bookingId": 754_207 + index,
          "offenderNo": nomis_id,
          "dateOfBirth": "1990-12-06", "convictedStatus": "Convicted",
          "categoryCode": "C", "imprisonmentStatus": "SENT03" }
      }

      bookings = offenders.map { |offender|
        { "bookingId": offender.fetch(:bookingId),
                                   "offenderNo": offender.fetch(:offenderNo),
                                   "agencyLocationId": prison.code,
                "sentenceDetail": { "sentenceExpiryDate": "2014-02-16", "automaticReleaseDate": "2011-01-28",
                   "licenceExpiryDate": "2014-02-07", "homeDetentionCurfewEligibilityDate": "2011-11-07",
                   "bookingId": 754_207, "sentenceStartDate": "2009-02-08",
                   "nonDtoReleaseDate": "2012-03-17", "nonDtoReleaseDateType": "ARD", "confirmedReleaseDate": "2012-03-17",
                   "releaseDate": "2012-03-17" } }
      }

      stub_offenders_for_prison(prison.code, offenders, bookings)
    end

    it 'omits the allocation which does not show up in Prison#offenders' do
      get :index, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(assigns(:inactive_poms).count).to eq(1)
      active_poms = assigns(:active_poms).map { |pom| { staff_id: pom.staff_id, tier_a: pom.tier_a, tier_b: pom.tier_b, tier_c: pom.tier_c, tier_d: pom.tier_d, total_cases: pom.total_cases } }

      expect(active_poms).to match_array [{ staff_id: active_staff_id, tier_a: 2, tier_b: 4, tier_c: 3, tier_d: 1, total_cases: 10 },
                                          { staff_id: unavailable_staff_id, tier_a: 0, tier_b: 0, tier_c: 0, tier_d: 0, total_cases: 0 }]
    end

    it 'shows the caseload on the show action' do
      get :show, params: { prison_id: prison.code, nomis_staff_id: active_staff_id }
      expect(response).to be_successful
      expect(assigns(:allocations).map(&:tier)).to match_array(["A", 'A', "B", "B", "B", "B", "C", "C", "C", "D"])
    end
  end
end
