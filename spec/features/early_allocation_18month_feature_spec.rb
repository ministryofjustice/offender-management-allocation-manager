# frozen_string_literal: true

require 'rails_helper'

feature 'early allocation when crossing 18 month threshold' do
  let(:prison) { create(:prison) }
  let(:user) { build(:pom) }

  context 'when early allocation prisoner transitions from > 18 months to < 18 months from release' do
    let(:nomis_offender) { build(:nomis_offender, prisonId: prison.code) }
    let(:offender_no) { nomis_offender.fetch(:prisonerNumber) }

    before do
      stub_offenders_for_prison(prison.code, [nomis_offender])
      stub_movements_for nomis_offender.fetch(:prisonerNumber), attributes_for_list(:movement, 1, toAgency: prison.code)
      stub_filtered_pom(prison.code, user)
      stub_keyworker prison.code, offender_no, build(:keyworker)

      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no,
                                                           early_allocations: [build(:early_allocation, prison: prison.code,
                                                                                                        created_within_referral_window: false)]))
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: user.staff_id, prison: prison.code)

      expect {
        offender_ids = EarlyAllocation.active_pre_referral_window.pluck(:nomis_offender_id).uniq
        offender_ids.each do |offender_no|
          SuitableForEarlyAllocationEmailJob.perform_now(offender_no)
        end
      }.to change(EmailHistory, :count).by(1)

      stub_signin_spo user, [prison.code]
    end

    it 'does some funky history record stuff' do
      visit history_prison_prisoner_allocation_path prison.code, offender_no
      # expect only 1 prison record
      expect(all('.govuk-grid-row').size).to eq(1)
      # and expect 3 timeline items (the allocation itself, plus 2 emails)

      within '.govuk-grid-row:nth-of-type(1)' do
        expect(all('.moj-timeline__item').size).to eq(3)
      end
    end
  end
end
