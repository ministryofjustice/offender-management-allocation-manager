# frozen_string_literal: true

require 'rails_helper'

feature 'summary summary feature' do
  before do
    signin_spo_user
  end

  describe 'awaiting summary table' do
    let(:prison) { 'LEI' }

    it 'displays offenders awaiting information', vcr: { cassette_name: 'prison_api/awaiting_information_feature' } do
      visit missing_information_prison_prisoners_path(prison)

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Add missing details')
      expect(page).to have_css('.pagination ul.links li', count: 16)
    end

    it 'displays offenders pending allocation', vcr: { cassette_name: 'prison_api/awaiting_allocation_feature' } do
      visit unallocated_prison_prisoners_path(prison)

      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Add missing details')
    end

    context 'with allocations' do
      let(:first) { 'G7806VO' }
      let(:last) { 'G6951VK' }
      let(:prison) { 'LEI' }

      before do
        Timecop.travel Date.new(2019, 6, 20) do
          create(:case_information, offender: build(:offender, nomis_offender_id: first))
          create(:allocation_history, prison: prison, nomis_offender_id: first)
        end
        Timecop.travel Date.new(2019, 6, 30) do
          create(:case_information, offender: build(:offender, nomis_offender_id: last))
          create(:allocation_history, prison: prison, nomis_offender_id: last)
        end
      end

      it 'displays offenders already allocated', vcr: { cassette_name: 'prison_api/allocated_offenders_feature' } do
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
