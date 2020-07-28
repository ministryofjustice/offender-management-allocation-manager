require 'rails_helper'

RSpec.describe CaseloadController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:staff_id) { 456_987 }
  let(:poms) {
    [
      build(:pom,
            firstName: 'Alice',
            staffId:  staff_id,
            position: RecommendationService::PRISON_POM)
    ]
  }

  before do
    stub_poms(prison, poms)
    stub_signed_in_pom(prison, staff_id, 'alice')
  end

  describe '#handover_start' do
    before do
      stub_offenders_for_prison(prison, [offender], bookings)
      create(:case_information, case_allocation: case_allocation, nomis_offender_id: offender.fetch(:offenderNo))
      create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: staff_id, prison: prison)
    end

    let(:offender) { attributes_for(:offender) }

    context 'when NPS' do
      let(:today_plus_36_weeks) { (Time.zone.today + 36.weeks).to_s }
      let(:bookings) {
        [offender].map { |o|
          b = attributes_for(:booking).merge(offenderNo: o.fetch(:offenderNo),
                                             bookingId: o.fetch(:bookingId))
          b.fetch(:sentenceDetail)[:paroleEligibilityDate] = today_plus_36_weeks
          b
        }
      }
      let(:case_allocation) { 'NPS' }

      it 'can pull back a NPS offender due for handover' do
        get :handover_start, params: { prison_id: prison }
        expect(response).to be_successful
        expect(assigns(:upcoming_handovers).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
      end
    end

    context 'when CRC' do
      let(:bookings) {
        [offender].map { |o|
          b = attributes_for(:booking).merge(offenderNo: o.fetch(:offenderNo),
                                             bookingId: o.fetch(:bookingId))
          b.fetch(:sentenceDetail)[:automaticReleaseDate] = today_plus_13_weeks
          b
        }
      }
      let(:case_allocation) { 'CRC' }
      let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }

      pending 'can pull back a CRC offender due for handover' do
        get :handover_start, params: { prison_id: prison }
        expect(response).to be_successful
        expect(assigns(:upcoming_handovers).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
      end
    end
  end

  context 'with 3 offenders', :versioning do
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.today - 1.day }

    let(:offenders) { attributes_for_list(:offender, 3).sort_by { |x| x.fetch(:lastName) } }

    before do
      bookings = offenders.map { |o|
        attributes_for(:booking).merge(offenderNo: o.fetch(:offenderNo),
                                       bookingId: o.fetch(:bookingId))
      }

      stub_offenders_for_prison(prison, offenders, bookings)

      # Need to create history records because AllocatedOffender#new_case? doesn't cope otherwise
      offenders.each do |offender|
        create(:case_information, nomis_offender_id: offender.fetch(:offenderNo))
        alloc = create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: staff_id, prison: prison)
        alloc.update!(primary_pom_nomis_id: staff_id,
                      event: Allocation::REALLOCATE_PRIMARY_POM,
                      event_trigger: Allocation::USER)
      end
    end

    describe '#index' do
      it 'returns the caseload' do
        get :index, params: { prison_id: prison }
        expect(response).to be_successful

        expect(assigns(:allocations).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
      end
    end

    describe '#new' do
      it 'returns the caseload' do
        get :new, params: { prison_id: prison }
        expect(response).to be_successful

        expect(assigns(:new_cases).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
      end
    end
  end
end
