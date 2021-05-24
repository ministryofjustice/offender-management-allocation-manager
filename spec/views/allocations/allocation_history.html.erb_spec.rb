require 'rails_helper'

RSpec.describe "allocations/history", type: :view do
  let(:dummy_version) { Struct.new(:object_changes).new({ 'updated_at' => [now, now] }.to_yaml) }
  let(:page) { Nokogiri::HTML(rendered) }
  let(:prison) { create(:prison) }
  let(:offender) { build(:hmpps_api_offender) }
  let(:now) { Time.zone.now }

  before do
    assign(:prison, prison)
    assign(:prisoner, offender)
    assign(:pom_emails, {})
    assign(:early_allocations, early_allocations)
  end

  context 'with early allocations' do
    before do
      assign(:history, [])
      assign(:email_histories, [])

      render
    end

    shared_examples 'view link' do
      it 'links to the Early Allocation view page' do
        view_link = page.css('.moj-timeline__description a').last
        expected_href = prison_prisoner_early_allocation_path(prison.code, ea.nomis_offender_id, ea.id)
        expect(view_link.text).to eq('View saved assessment')
        expect(view_link['href']).to eq(expected_href)
      end
    end

    context 'with an ineligible early allocation' do
      let(:ea) { create(:early_allocation, :ineligible, created_at: DateTime.new(2019, 11, 19, 11, 28, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome: not eligible.')
      end

      include_examples 'view link'
    end

    context 'with an eligible unsent early alloc' do
      let(:ea) { create(:early_allocation, :unsent, created_at: DateTime.new(2019, 11, 19, 11, 28, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome: eligible.')
        expect(page.css('.moj-timeline__description')).to have_content('The assessment has not been sent to the community probation team.')
        expect(page.css('.moj-timeline__description')).to have_content('We will remind the allocated POM to make a new assessment 18 months before release.')
      end

      include_examples 'view link'
    end

    context 'with an ineligible unsent early alloc' do
      let(:ea) { create(:early_allocation, :unsent, :ineligible, created_at: DateTime.new(2019, 11, 19, 11, 28, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome: not eligible.')
      end

      include_examples 'view link'
    end

    context 'with a discretionary unsent early alloc' do
      let(:ea) { create(:early_allocation, :unsent, :discretionary, created_at: DateTime.new(2019, 11, 19, 11, 28, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome: discretionary.')
        expect(page.css('.moj-timeline__description')).to have_content('The assessment has not been sent to the community probation team.')
        expect(page.css('.moj-timeline__description')).to have_content('We will remind the allocated POM to make a new assessment 18 months before release.')
      end

      include_examples 'view link'
    end

    context 'with an eligible early allocation' do
      let(:ea) { create(:early_allocation, created_at: DateTime.new(2019, 11, 19, 11, 28, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome: eligible.')
        expect(page.css('.moj-timeline__description')).to have_content('The case handover date has been updated. The community probation team will allocate a COM to take responsibility for this case early.')
      end

      include_examples 'view link'
    end

    context 'with a disretionary early allocation' do
      let(:ea) { create(:early_allocation, :discretionary, created_at: DateTime.new(2019, 11, 19, 11, 28, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome is discretionary.')
        expect(page.css('.moj-timeline__description')).to have_content('The community probation team will need to make a decision.')
      end

      include_examples 'view link'
    end

    context 'when community accept the case' do
      let(:ea) { create(:early_allocation, :discretionary_accepted, created_at: DateTime.new(2019, 11, 19, 11, 28, 0), updated_at: DateTime.new(2019, 11, 21, 11, 35, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ['Early allocation decision recorded', "Early allocation assessment form completed"]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("21st November 2019 (11:35)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.updated_by_lastname}, #{ea.updated_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome is discretionary.')
        expect(page.css('.moj-timeline__description')).to have_content('The community probation team will need to make a decision.')
        expect(page.css('.moj-timeline__description')).to have_content('The community probation team accepted the early allocation referral.')
        expect(page.css('.moj-timeline__description')).to have_content('The case handover date has been updated. The community probation team will allocate a COM to take responsibility for this case early.')
      end

      include_examples 'view link'
    end

    context 'when community reject the case' do
      let(:ea) { create(:early_allocation, :discretionary_declined, created_at: DateTime.new(2019, 11, 19, 11, 28, 0), updated_at: DateTime.new(2019, 11, 21, 11, 35, 0)) }
      let(:early_allocations) { [ea] }

      it 'shows a single record' do
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ['Early allocation decision recorded', "Early allocation assessment form completed",]
        expect(page.css('.moj-timeline__date')).to have_text("19th November 2019 (11:28)")
        expect(page.css('.moj-timeline__date')).to have_text("21st November 2019 (11:35)")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.created_by_lastname}, #{ea.created_by_firstname}")
        expect(page.css('.moj-timeline__date')).to have_text("by #{ea.updated_by_lastname}, #{ea.updated_by_firstname}")

        expect(page.css('.moj-timeline__description')).to have_content('Assessment outcome is discretionary.')
        expect(page.css('.moj-timeline__description')).to have_content('The community probation team will need to make a decision.')
        expect(page.css('.moj-timeline__description')).to have_content('The community probation team declined the early allocation referral.')
      end

      include_examples 'view link'
    end
  end

  context 'without early alloc' do
    let(:early_allocations) { [] }

    before do
      assign(:email_histories, [])
    end

    context 'when allocator completes an override against the recommendation (allocation)' do
      before do
        old_versions =
          [
            build(:allocation, override_reasons: ["suitability"], suitability_detail: "Too high risk"),
            build(:allocation, override_reasons: ["suitability"], event: Allocation::REALLOCATE_PRIMARY_POM, suitability_detail: "Continuity")
          ]

        assign(:history, [
          CaseHistory.new(nil, old_versions[0], dummy_version),
          CaseHistory.new(old_versions[0], old_versions[1], dummy_version),
        ])
      end

      it 'shows a reason why in the allocation history' do
        render
        expect(page.css('#override-reason-allocation').text).to include 'Too high risk'
        expect(page.css('#override-reason-reallocation').text).to include 'Continuity'
      end
    end

    # Their is a fix in this view to display incorrect data correctly due to a bug created in the Override Controller. Unfortunately this bad data
    # cannot easily be altered so to get around this it has been modified at the view level.
    context 'when a prisoner has moved to another prison' do
      before do
        old_versions =
          [
            build(:allocation, :primary, prison: prison_one),
            build(:allocation, :transfer, prison: prison_one),
            build(:allocation, :reallocation, :override, prison: prison_two)
          ]

        assign(:history, [
          CaseHistory.new(nil, old_versions[0], dummy_version),
          CaseHistory.new(old_versions[0], old_versions[1], dummy_version),
          CaseHistory.new(old_versions[1], old_versions[2], dummy_version),
        ])
      end

      let(:prison_one) { create(:prison).code }
      let(:prison_two) { create(:prison).code }

      it 'displays an allocation label in the allocation history' do
        render
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Prisoner allocated", "Prisoner unallocated", "Prisoner allocated"]
      end
    end

    context 'when a prisoner has been released' do
      before do
        assign(:history, [build(:allocation, :primary),
                          build(:allocation, :release)].
            map { |ah| CaseHistory.new(nil, ah, released_version) })
      end

      let(:released_version) { Struct.new(:object_changes).new({ 'updated_at' => [release_date_and_time, release_date_and_time] }.to_yaml) }
      let(:release_date_and_time) { DateTime.new(2019, 11, 19, 11, 28, 0) }

      it 'displays a release label and the release date and time in the allocation history' do
        render
        expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Prisoner unallocated", "Prisoner allocated"]
        expect(page.css('.moj-timeline__date')).to have_text('19th November 2019 (11:28)')
      end
    end
  end
end
