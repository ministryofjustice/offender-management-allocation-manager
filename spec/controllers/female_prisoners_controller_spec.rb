require 'rails_helper'

RSpec.describe FemalePrisonersController, type: :controller do
  let(:prison) { build :womens_prison }
  let(:test_strategy) { Flipflop::FeatureSet.current.test! }

  before do
    stub_offenders_for_prison(prison.code, offenders)
    stub_sso_data(prison.code)
    test_strategy.switch!(:womens_estate, true)
  end

  after do
    test_strategy.switch!(:womens_estate, false)
  end

  describe 'buckets' do
    before do
      create(:case_information, nomis_offender_id: offender_with_case_info_but_no_complexity_level.fetch(:offenderNo))
      create(:case_information, nomis_offender_id: offender_with_complexity_level_and_case_info.fetch(:offenderNo))

      create(:allocation, nomis_offender_id: allocated_offender_one.fetch(:offenderNo), prison: prison.code)
      create(:allocation, nomis_offender_id: allocated_offender_two.fetch(:offenderNo), prison: prison.code)
    end

    let(:offender_with_case_info_but_no_complexity_level) { build(:nomis_offender, complexityLevel: nil) }
    let(:offender_with_no_case_info_and_no_complexity_level) { build(:nomis_offender, complexityLevel: nil) }
    let(:offender_with_complexity_level_but_no_case_info) { build(:nomis_offender, complexityLevel: 'medium') }
    let(:offender_with_complexity_level_and_case_info) { build(:nomis_offender, complexityLevel: 'medium') }
    let(:allocated_offender_one) { build(:nomis_offender) }
    let(:allocated_offender_two) { build(:nomis_offender) }

    # new arrival - it's new and haven't matched with delius yet.
    let(:today) { Time.zone.today }

    let(:offender_arrived_today_with_no_complexity_or_case_info) {
      build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: today), complexityLevel: nil)
    }

    let(:offenders) {
      [offender_with_case_info_but_no_complexity_level,
       offender_with_complexity_level_but_no_case_info,
       offender_with_no_case_info_and_no_complexity_level,
       offender_with_complexity_level_and_case_info,
       allocated_offender_one,
       allocated_offender_two,
       offender_arrived_today_with_no_complexity_or_case_info
        ]
    }
    let(:missing_info_offenders) {
      [offender_with_case_info_but_no_complexity_level,
       offender_with_complexity_level_but_no_case_info,
       offender_with_no_case_info_and_no_complexity_level]
    }
    let(:allocated_offenders) {
      [allocated_offender_one,
       allocated_offender_two]
    }
    let(:unallocated_offenders) { [offender_with_complexity_level_and_case_info] }
    let(:new_arrival_offenders) { [offender_arrived_today_with_no_complexity_or_case_info] }

    it 'gives you the total count for each bucket and the offenders in the missing info bucket' do
      get :missing_information, params: { prison_id: prison.code }
      expect(response).to be_successful
      expect(assigns(:offenders).map(&:offender_no)).to match_array(missing_info_offenders.map { |o| o.fetch(:offenderNo) })
      check_bucket_counts
    end

    it 'gives you the total count for each bucket and the offenders in the allocated bucket' do
      get :allocated, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(assigns(:offenders).map(&:offender_no)).to match_array(allocated_offenders.map { |o| o.fetch(:offenderNo) })
      check_bucket_counts
    end

    it 'gives you the total count for each bucket and the offenders in the unallocated bucket' do
      get :unallocated, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(assigns(:offenders).map(&:offender_no)).to match_array(unallocated_offenders.map { |o| o.fetch(:offenderNo) })
      check_bucket_counts
    end

    it 'gives you the total count for each bucket and the offenders in the new arrivals bucket' do
      get :new_arrivals, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(assigns(:offenders).map(&:offender_no)).to match_array(new_arrival_offenders.map { |o| o.fetch(:offenderNo) })
      check_bucket_counts
    end

    def check_bucket_counts
      expect(assigns(:missing_info).size).to eq(3)
      expect(assigns(:allocated).size).to eq(2)
      expect(assigns(:unallocated).size).to eq(1)
      expect(assigns(:new_arrivals).size).to eq(1)
    end
  end

  describe 'sorting' do
    let(:one_day_ago) { Time.zone.today - 1.day }
    let(:two_days_ago) { Time.zone.today - 2.days }
    let(:three_days_ago) { Time.zone.today - 3.days }
    let(:four_days_ago) { Time.zone.today - 4.days }

    let(:release_date_one) { Time.zone.today + 8.months }
    let(:release_date_two) { Time.zone.today + 9.months }
    let(:release_date_three) { Time.zone.today + 10.months }
    let(:release_date_four) { Time.zone.today + 11.months }

    let(:offenders) { [offender_c, offender_a, offender_b, offender_d] }
    let(:offenders_prisoner_name_ascending_order) { [offender_a, offender_b, offender_c, offender_d] }
    let(:offenders_awaiting_allocation_ascending_order) { [offender_b, offender_c, offender_a, offender_d] }

    let(:offender_a) {
      build(:nomis_offender,
            sentence: attributes_for(:sentence_detail,
                                     sentenceStartDate: three_days_ago,
                                     conditionalReleaseDate: release_date_four),
            lastName: 'Austin')
    }
    let(:offender_b) {
      build(:nomis_offender,
            sentence: attributes_for(:sentence_detail,
                                     sentenceStartDate: one_day_ago,
                                     conditionalReleaseDate: release_date_three),
            lastName: 'Blackburn')
    }
    let(:offender_c) {
      build(:nomis_offender,
            sentence: attributes_for(:sentence_detail,
                                     sentenceStartDate: two_days_ago,
                                     conditionalReleaseDate: nil),
            lastName: 'Carsley')
    }
    let(:offender_d) {
      build(:nomis_offender,
            sentence: attributes_for(:sentence_detail,
                                     sentenceStartDate: four_days_ago,
                                     conditionalReleaseDate: release_date_two),
            lastName: 'Darrel')
    }

    describe 'missing_information' do
      it 'sorts name by ascending order' do
        assert_sort_ascending(:missing_information, offenders_prisoner_name_ascending_order, 'last_name asc')
      end

      it 'sorts name by descending order' do
        assert_sort_descending(:missing_information, offenders_prisoner_name_ascending_order, 'last_name desc asc')
      end

      it 'sorts by waiting for allocation descending' do
        assert_sort_descending(:missing_information, offenders_awaiting_allocation_ascending_order, 'awaiting_allocation_for desc')
      end

      it 'sorts by waiting for allocation ascending' do
        assert_sort_ascending(:missing_information, offenders_awaiting_allocation_ascending_order, 'awaiting_allocation_for asc')
      end
    end

    describe 'unallocated' do
      before do
        create(:case_information, tier: 'D', nomis_offender_id: offender_a.fetch(:offenderNo))
        create(:case_information, tier: 'C', nomis_offender_id: offender_b.fetch(:offenderNo))
        create(:case_information, tier: 'B', nomis_offender_id: offender_c.fetch(:offenderNo))
        create(:case_information, tier: 'A', nomis_offender_id: offender_d.fetch(:offenderNo))

        allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_a.fetch(:offenderNo)).and_return('medium')
        allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_b.fetch(:offenderNo)).and_return('low')
        allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_c.fetch(:offenderNo)).and_return('medium')
        allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_d.fetch(:offenderNo)).and_return('high')

        create(:responsibility, nomis_offender_id: offender_c.fetch(:offenderNo), value: Responsibility::PROBATION)
        create(:responsibility, nomis_offender_id: offender_d.fetch(:offenderNo), value: Responsibility::PROBATION)
        create(:responsibility, nomis_offender_id: offender_a.fetch(:offenderNo), value: Responsibility::PRISON)
        create(:responsibility, nomis_offender_id: offender_b.fetch(:offenderNo), value: Responsibility::PRISON)
      end

      let(:offenders_earliest_release_date_ascending_order) { [offender_c, offender_d, offender_b, offender_a] }

      let(:offenders_tiers_ascending_order) { [offender_d, offender_c, offender_b, offender_a] }

      let(:offenders) { [offender_c, offender_a, offender_b, offender_d] }

      it 'sorts name by ascending order' do
        assert_sort_ascending(:unallocated, offenders_prisoner_name_ascending_order, 'last_name asc')
      end

      it 'sorts name by descending order' do
        assert_sort_descending(:unallocated, offenders_prisoner_name_ascending_order, 'last_name desc')
      end

      it 'sorts by tier ascending' do
        assert_sort_ascending(:unallocated, offenders_tiers_ascending_order, 'tier asc')
      end

      it 'sorts by tier descending' do
        assert_sort_descending(:unallocated, offenders_tiers_ascending_order, 'tier desc')
      end

      it 'sorts by earliest release date ascending' do
        assert_sort_ascending(:unallocated, offenders_earliest_release_date_ascending_order, 'earliest_release_date asc')
      end

      it 'sorts by earliest release date descending' do
        assert_sort_descending(:unallocated, offenders_earliest_release_date_ascending_order, 'earliest_release_date desc')
      end

      it 'sorts by case owner ascending' do
        get :unallocated, params: { prison_id: prison.code, sort: 'case_owner asc' } # Default direction is asc.
        expect(assigns(:offenders).map(&:case_owner)).to eq(["Community", "Community", "Custody", "Custody",])
      end

      it 'sorts by case owner descending' do
        get :unallocated, params: { prison_id: prison.code, sort: 'case_owner desc' } # Default direction is asc.
        expect(assigns(:offenders).map(&:case_owner)).to eq(["Custody", "Custody", "Community", "Community"])
      end

      it 'sorts by waiting for allocation ascending' do
        assert_sort_ascending(:unallocated, offenders_awaiting_allocation_ascending_order, 'awaiting_allocation_for asc')
      end

      it 'sorts by waiting for allocation descending' do
        assert_sort_descending(:unallocated, offenders_awaiting_allocation_ascending_order, 'awaiting_allocation_for desc')
      end
    end

    describe 'allocated' do
      before do
        create(:allocation, primary_pom_name: pom_one.full_name,  nomis_offender_id: offender_a.fetch(:offenderNo), prison: prison.code)
        create(:allocation, primary_pom_name: pom_two.full_name,  nomis_offender_id: offender_b.fetch(:offenderNo), prison: prison.code)
        create(:allocation, primary_pom_name: pom_three.full_name, nomis_offender_id: offender_c.fetch(:offenderNo), prison: prison.code)
        create(:allocation, primary_pom_name: pom_four.full_name,  nomis_offender_id: offender_d.fetch(:offenderNo), prison: prison.code)
      end

      let(:offenders) { [offender_c, offender_a, offender_b, offender_d] }
      let(:pom_one) { build(:pom, firstName: 'Olivia', lastName: 'Mann') }
      let(:pom_two) { build(:pom, firstName: 'Rachel', lastName: 'Borchard') }
      let(:pom_three) { build(:pom, firstName: 'Anna', lastName: 'Farmer') }
      let(:pom_four) { build(:pom, firstName: 'Sam', lastName: 'Northey') }

      it 'contains POM name' do
        get :allocated, params: { prison_id: prison.code } # Default direction is asc.
        expect(assigns(:offenders).map(&:allocated_pom_name)).to match_array(["Mann, Olivia", "Borchard, Rachel", "Farmer, Anna", "Northey, Sam"])
      end

      it 'sorts name by ascending order' do
        assert_sort_ascending(:allocated, offenders_prisoner_name_ascending_order, 'last_name asc')
      end

      it 'sorts name by descending order' do
        assert_sort_descending(:allocated, offenders_prisoner_name_ascending_order, 'last_name desc')
      end

      it 'sorts by waiting for allocation descending' do
        assert_sort_descending(:allocated, offenders_awaiting_allocation_ascending_order, 'awaiting_allocation_for desc')
      end

      it 'sorts by waiting for allocation ascending' do
        assert_sort_ascending(:allocated, offenders_awaiting_allocation_ascending_order, 'awaiting_allocation_for asc')
      end
    end

    def assert_sort_ascending(action, expected_result, sort_by)
      get action, params: { prison_id: prison.code, sort: sort_by } # Default direction is asc.
      expect(assigns(:offenders).map(&:offender_no)).to eq(expected_result.map { |o| o.fetch(:offenderNo) })
    end

    def assert_sort_descending(action, expected_result, sort_by)
      get action, params: { prison_id: prison.code, sort: sort_by } # Default direction is asc.
      expect(assigns(:offenders).map(&:offender_no)).to eq(expected_result.reverse.map { |o| o.fetch(:offenderNo) })
    end
  end
end
