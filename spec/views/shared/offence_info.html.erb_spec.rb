require 'rails_helper'

RSpec.describe "shared/offence_info", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:prison) { build(:prison) }
  let(:api_offender) {
    build(:hmpps_api_offender,
          prisonId: prison.code,
          sentence: attributes_for(:sentence_detail, :indeterminate, tariffDate: ted, paroleEligibilityDate: ped))
  }
  let(:offender) { build(:mpc_offender, prison: prison, prison_record: api_offender, offender: build(:offender)) }

  before do
    assign(:prison, prison)
    assign(:prisoner, offender)
    render 'shared/offence_info', editable_prd: true
  end

  context 'with a past TED' do
    let(:ted) { Time.zone.today - 2.days }

    context 'when a TED and PED are both in the past' do
      let(:ped) { Time.zone.today - 2.days }

      it 'shows the PRD update link' do
        expect(page.css('#parole-review-date')).to have_content 'Update'
      end
    end

    context 'when a PED is missing' do
      let(:ped) { nil }

      it 'shows the PRD update link' do
        expect(page.css('#parole-review-date')).to have_content 'Update'
      end
    end

    context 'when PED is in the future' do
      let(:ped) { Time.zone.today + 2.days }

      it 'does not show the PRD update link' do
        expect(page.css('#parole-review-date')).not_to have_content 'Update'
      end
    end
  end

  context 'with a past PED' do
    let(:ped) { Time.zone.today - 2.days }

    context 'when a TED is missing' do
      let(:ted) { nil }

      it 'shows the PRD update link' do
        expect(page.css('#parole-review-date')).to have_content 'Update'
      end
    end

    context 'when a TED is in the future' do
      let(:ted) { Time.zone.today + 2.days }

      it 'does not show the PRD update link' do
        expect(page.css('#parole-review-date')).not_to have_content 'Update'
      end
    end
  end
end
