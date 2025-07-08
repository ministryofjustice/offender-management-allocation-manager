# frozen_string_literal: true

require 'rails_helper'

feature 'summary summary feature' do
  let(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }
  let(:offenders) { build_list(:nomis_offender, 3) }

  let!(:case_info) do
    create(:case_information, offender: build(:offender, nomis_offender_id: offenders.last.fetch(:prisonerNumber)))
  end

  before do
    stub_bank_holidays
    stub_signin_spo(build(:pom), prison.code)
    stub_offenders_for_prison(prison.code, offenders)
  end

  describe 'awaiting summary table' do
    it 'displays offenders missing information' do
      visit missing_information_prison_prisoners_path(prison)

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Add missing details (2)')
    end

    it 'displays offenders pending allocation' do
      visit unallocated_prison_prisoners_path(prison)

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Make allocations (1)')
    end

    context 'with allocations' do
      # These 2 offenders are left without case information record
      let(:first) { offenders[0].fetch(:prisonerNumber) }
      let(:last) { offenders[1].fetch(:prisonerNumber) }

      before do
        Timecop.travel Date.new(2019, 6, 20) do
          create(:case_information, offender: build(:offender, nomis_offender_id: first))
          create(:allocation_history, prison: prison.code, nomis_offender_id: first)
        end
        Timecop.travel Date.new(2019, 6, 30) do
          create(:case_information, offender: build(:offender, nomis_offender_id: last))
          create(:allocation_history, prison: prison.code, nomis_offender_id: last)
        end
      end

      it 'displays offenders already allocated' do
        visit allocated_prison_prisoners_path(prison)
        expect(page).to have_css('.moj-sub-navigation__item')
        expect(page).to have_content('See allocations')
        # forward sort
        click_link 'Allocation date'
        # The 'hint' contains the offender id
        expect(all('.govuk-hint').map(&:text)).to eq [first, last]

        # reverse sort
        click_link 'Allocation date'
        expect(all('.govuk-hint').map(&:text)).to eq [last, first]

        # forward sort
        click_link 'Allocation date'
        expect(all('.govuk-hint').map(&:text)).to eq [first, last]
      end
    end
  end
end
