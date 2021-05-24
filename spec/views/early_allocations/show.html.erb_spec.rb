# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "early_allocations/show", type: :view do
  before do
    assign(:case_information, build(:case_information))
    assign(:offender, build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail)))

    assign(:early_allocation, early_allocation)
    assign(:referrer, referrer)
    render
  end

  let(:page) { Nokogiri::HTML(rendered) }
  let(:referrer) { nil }

  context 'when reviewing an elibigle early assessment' do
    let(:early_allocation) {  create(:early_allocation, :eligible, created_at: '05/11/2021', created_by_firstname: 'Olivia', created_by_lastname: 'Mann') }

    it 'shows the previous assessment date' do
      expect(page.css('#assessment-date-label')).to have_text('Assessment date')
      expect(page.css('#assessment-date')).to have_text('05/11/2021')
    end

    it 'shows the previous POM who made the assessment' do
      expect(page.css('#pom-name-label')).to have_text('POM name')
      expect(page.css('#pom-name')).to have_text('Mann, Olivia')
    end

    describe 'outcome' do
      context 'when the outcome is eligible' do
        it 'shows the outcome' do
          expect(page.css('#outcome-label')).to have_text('Outcome')
          expect(page.css('#outcome')).to have_text('Eligible - the community probation team will take responsibility for this case early')
        end
      end
    end

    describe 'backlink' do
      context 'when the referer is nil' do
        it 'links to home' do
          expect(page).to have_link('Back', href: '/')
        end
      end

      context 'when the referer is a page' do
        let(:referrer) { '/fred' }

        it 'links to that page' do
          expect(page).to have_link('Back', href: '/fred')
        end
      end
    end
  end

  context 'when eligible and unsent' do
    let(:early_allocation) { create(:early_allocation, :eligible, :unsent) }

    it 'shows the outcome' do
      expect(page).to have_text('Eligible - assessment not sent to the community probation team')
    end
  end

  context 'when not eligible' do
    let(:early_allocation) { create(:early_allocation, :ineligible) }

    it 'shows the outcome' do
      expect(page).to have_text('Not eligible')
    end
  end

  context 'when discretionary - not sent' do
    let(:early_allocation) { create(:early_allocation, :discretionary, :unsent) }

    it 'shows the outcome' do
      expect(page).to have_text('Discretionary - assessment not sent to the community probation team')
    end
  end

  context 'when discretionary - accepted' do
    let(:early_allocation) { create(:early_allocation, :discretionary, community_decision: true) }

    it 'shows the outcome' do
      expect(page).to have_text('Eligible - the community probation team will take responsibility for this case early')
    end
  end

  context 'when discretionary - waiting' do
    let(:early_allocation) { create(:early_allocation, :discretionary) }

    it 'shows the outcome' do
      expect(page).to have_text('Discretionary - the community probation team will make a decision')
    end
  end
end
