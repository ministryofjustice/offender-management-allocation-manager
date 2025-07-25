require 'rails_helper'

RSpec.describe PrisonersController, type: :controller do
  context 'with a womens prison' do
    let(:prison) { create(:womens_prison) }

    before do
      stub_offenders_for_prison(prison.code, offenders)
      stub_sso_data(prison.code)
    end

    describe 'buckets' do
      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_with_case_info_but_no_complexity_level.fetch(:prisonerNumber)))
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_with_complexity_level_and_case_info.fetch(:prisonerNumber)))

        create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender_one.fetch(:prisonerNumber)))
        create(:allocation_history, nomis_offender_id: allocated_offender_one.fetch(:prisonerNumber), prison: prison.code)
        create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender_two.fetch(:prisonerNumber)))
        create(:allocation_history, nomis_offender_id: allocated_offender_two.fetch(:prisonerNumber), prison: prison.code)
      end

      let(:offender_with_case_info_but_no_complexity_level) { build(:nomis_offender, complexityLevel: nil) }
      let(:offender_with_no_case_info_and_no_complexity_level) { build(:nomis_offender, complexityLevel: nil) }
      let(:offender_with_complexity_level_but_no_case_info) { build(:nomis_offender, complexityLevel: 'medium') }
      let(:offender_with_complexity_level_and_case_info) { build(:nomis_offender, complexityLevel: 'medium') }
      let(:allocated_offender_one) { build(:nomis_offender) }
      let(:allocated_offender_two) { build(:nomis_offender) }

      let(:offenders) do
        [offender_with_case_info_but_no_complexity_level,
         offender_with_complexity_level_but_no_case_info,
         offender_with_no_case_info_and_no_complexity_level,
         offender_with_complexity_level_and_case_info,
         allocated_offender_one,
         allocated_offender_two,
        ]
      end
      let(:missing_info_offenders) do
        [offender_with_case_info_but_no_complexity_level,
         offender_with_complexity_level_but_no_case_info,
         offender_with_no_case_info_and_no_complexity_level]
      end
      let(:allocated_offenders) do
        [allocated_offender_one,
         allocated_offender_two]
      end
      let(:unallocated_offenders) { [offender_with_complexity_level_and_case_info] }

      it 'gives you the total count for each bucket and the offenders in the missing info bucket' do
        get :missing_information, params: { prison_id: prison.code }
        expect(response).to be_successful
        expect(assigns(:offenders).map(&:offender_no)).to match_array(missing_info_offenders.map { |o| o.fetch(:prisonerNumber) })
        check_bucket_counts
      end

      it 'gives you the total count for each bucket and the offenders in the allocated bucket' do
        get :allocated, params: { prison_id: prison.code }
        expect(response).to be_successful

        expect(assigns(:offenders).map(&:offender_no)).to match_array(allocated_offenders.map { |o| o.fetch(:prisonerNumber) })
        check_bucket_counts
      end

      it 'gives you the total count for each bucket and the offenders in the unallocated bucket' do
        get :unallocated, params: { prison_id: prison.code }
        expect(response).to be_successful

        expect(assigns(:offenders).map(&:offender_no)).to match_array(unallocated_offenders.map { |o| o.fetch(:prisonerNumber) })
        check_bucket_counts
      end

      def check_bucket_counts
        expect(assigns(:missing_info).size).to eq(3)
        expect(assigns(:allocated).size).to eq(2)
        expect(assigns(:unallocated).size).to eq(1)
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

      let(:offender_a) do
        build(:nomis_offender,
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: three_days_ago,
                                       conditionalReleaseDate: release_date_four),
              lastName: 'Austin')
      end
      let(:offender_b) do
        build(:nomis_offender,
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: one_day_ago,
                                       conditionalReleaseDate: release_date_three),
              lastName: 'Blackburn')
      end
      let(:offender_c) do
        build(:nomis_offender,
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: two_days_ago,
                                       conditionalReleaseDate: nil),
              lastName: 'Carsley')
      end
      let(:offender_d) do
        build(:nomis_offender,
              sentence: attributes_for(:sentence_detail,
                                       sentenceStartDate: four_days_ago,
                                       conditionalReleaseDate: release_date_two),
              lastName: 'Darrel')
      end

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
          create(:case_information, tier: 'D', offender: build(:offender, nomis_offender_id: offender_a.fetch(:prisonerNumber)))
          create(:case_information, tier: 'C', offender: build(:offender, nomis_offender_id: offender_b.fetch(:prisonerNumber)))
          create(:case_information, tier: 'B', offender: build(:offender, nomis_offender_id: offender_c.fetch(:prisonerNumber)))
          create(:case_information, tier: 'A', offender: build(:offender, nomis_offender_id: offender_d.fetch(:prisonerNumber)))

          allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_a.fetch(:prisonerNumber)).and_return('medium')
          allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_b.fetch(:prisonerNumber)).and_return('low')
          allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_c.fetch(:prisonerNumber)).and_return('medium')
          allow(HmppsApi::ComplexityApi).to receive(:get_complexity).with(offender_d.fetch(:prisonerNumber)).and_return('high')

          create(:responsibility, nomis_offender_id: offender_c.fetch(:prisonerNumber), value: Responsibility::PROBATION)
          create(:responsibility, nomis_offender_id: offender_d.fetch(:prisonerNumber), value: Responsibility::PROBATION)
          create(:responsibility, nomis_offender_id: offender_a.fetch(:prisonerNumber), value: Responsibility::PRISON)
          create(:responsibility, nomis_offender_id: offender_b.fetch(:prisonerNumber), value: Responsibility::PRISON)
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
          create(:case_information, offender: build(:offender, nomis_offender_id: offender_a.fetch(:prisonerNumber)))
          create(:allocation_history, primary_pom_name: pom_one.full_name,  nomis_offender_id: offender_a.fetch(:prisonerNumber), prison: prison.code)
          create(:case_information, offender: build(:offender, nomis_offender_id: offender_b.fetch(:prisonerNumber)))
          create(:allocation_history, primary_pom_name: pom_two.full_name,  nomis_offender_id: offender_b.fetch(:prisonerNumber), prison: prison.code)
          create(:case_information, offender: build(:offender, nomis_offender_id: offender_c.fetch(:prisonerNumber)))
          create(:allocation_history, primary_pom_name: pom_three.full_name, nomis_offender_id: offender_c.fetch(:prisonerNumber), prison: prison.code)
          create(:case_information, offender: build(:offender, nomis_offender_id: offender_d.fetch(:prisonerNumber)))
          create(:allocation_history, primary_pom_name: pom_four.full_name,  nomis_offender_id: offender_d.fetch(:prisonerNumber), prison: prison.code)
        end

        let(:offenders) { [offender_c, offender_a, offender_b, offender_d] }
        let(:pom_one) { build(:pom, firstName: 'Olivia', lastName: 'Mann') }
        let(:pom_two) { build(:pom, firstName: 'Rachel', lastName: 'Borchard') }
        let(:pom_three) { build(:pom, firstName: 'Anna', lastName: 'Farmer') }
        let(:pom_four) { build(:pom, firstName: 'Sam', lastName: 'Northey') }

        it 'contains POM name' do
          get :allocated, params: { prison_id: prison.code } # Default direction is asc.
          expect(assigns(:offenders).map(&:formatted_pom_name)).to match_array(["Anna Farmer", "Olivia Mann", "Rachel Borchard", "Sam Northey"])
        end

        it 'sorts name by ascending order' do
          assert_sort_ascending(:allocated, offenders_prisoner_name_ascending_order, 'last_name asc')
        end

        it 'sorts name by descending order' do
          assert_sort_descending(:allocated, offenders_prisoner_name_ascending_order, 'last_name desc')
        end
      end

      def assert_sort_ascending(action, expected_result, sort_by)
        get action, params: { prison_id: prison.code, sort: sort_by } # Default direction is asc.
        expect(assigns(:offenders).map(&:offender_no)).to eq(expected_result.map { |o| o.fetch(:prisonerNumber) })
      end

      def assert_sort_descending(action, expected_result, sort_by)
        get action, params: { prison_id: prison.code, sort: sort_by } # Default direction is asc.
        expect(assigns(:offenders).map(&:offender_no)).to eq(expected_result.reverse.map { |o| o.fetch(:prisonerNumber) })
      end
    end
  end

  context 'with a mens prison' do
    let(:prison) { create(:prison).code }

    before { stub_sso_data(prison) }

    context 'with 4 offenders' do
      let(:today_plus_10_days) { (Time.zone.today + 10.days).to_s }
      let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }

      before do
        offenders = [
          build(:nomis_offender,
                prisonerNumber: "G7514GW",
                imprisonmentStatus: "LR",
                lastName: 'SMITH',
                sentence: attributes_for(:sentence_detail, sentenceStartDate: "2011-01-20")),
          build(:nomis_offender, prisonerNumber: "G1234GY", imprisonmentStatus: "LIFE",
                                 lastName: 'Minate-Offender',
                                 sentence: attributes_for(:sentence_detail,
                                                          sentenceStartDate: "2009-02-08",
                                                          automaticReleaseDate: "2011-01-28")),
          build(:nomis_offender, prisonerNumber: "G1234VV",
                                 lastName: 'JONES',
                                 sentence: attributes_for(:sentence_detail,
                                                          sentenceStartDate: "2019-02-08",
                                                          automaticReleaseDate: today_plus_13_weeks)),
          build(:nomis_offender, prisonerNumber: "G4234GG",
                                 imprisonmentStatus: "SENT03",
                                 firstName: "Fourth", lastName: "Offender",
                                 sentence: attributes_for(:sentence_detail,
                                                          automaticReleaseDate: today_plus_10_days,
                                                          homeDetentionCurfewActualDate: today_plus_10_days,
                                                          sentenceStartDate: "2019-02-08",
                                                         ))
        ]
        create(:case_information, enhanced_resourcing: true, offender: build(:offender, nomis_offender_id: 'G4234GG'))

        stub_offenders_for_prison(prison, offenders)
      end

      context 'without new arrivals' do
        before do
          stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN")
            .with(body: %w[G7514GW G1234GY G1234VV G4234GG].to_json)
            .to_return(body: [attributes_for(:movement, offenderNo: 'G7514GW', toAgency: prison, movementDate: Date.new(2018, 10, 1).to_s),
                              attributes_for(:movement, offenderNo: 'G1234VV', toAgency: prison, movementDate: Date.new(2018, 9, 1).to_s)].to_json)
        end

        it 'gets missing_information records' do
          get :missing_information, params: { prison_id: prison }
          # Expecting offender (2) to use sentenceStartDate as it is newer than last arrival date in prison
          off = assigns(:offenders).map { |o| [o.offender_no, Time.zone.today - o.awaiting_allocation_for] }.to_h
          expect(off).to eq("G1234GY" => Date.new(2009, 2, 8),
                            "G7514GW" => Date.new(2018, 10, 1),
                            "G1234VV" => Date.new(2019, 2, 8))
        end

        it 'sorts ascending by default' do
          get :missing_information, params: { prison_id: prison, sort: 'last_name' } # Default direction is asc.
          expect(assigns(:offenders).map(&:last_name)).to eq(%w[JONES Minate-Offender SMITH])
        end

        it 'sorts descending' do
          get :missing_information, params: { prison_id: prison, sort: 'last_name desc' }

          expect(assigns(:offenders).map(&:last_name)).to eq(%w[SMITH Minate-Offender JONES])
        end
      end
    end

    context 'when user is a POM' do
      let(:poms) do
        [
          build(:pom,
                firstName: 'Alice',
                position: RecommendationService::PRISON_POM,
                staffId: 1
               )
        ]
      end

      before do
        stub_poms(prison, poms)
        stub_signed_in_pom(prison, 1)
      end

      it 'is not visible' do
        get :missing_information, params: { prison_id: prison }
        expect(response).to redirect_to('/401')
      end
    end

    context 'with enough offenders to page' do
      let(:offenders) { build_list(:nomis_offender, 120) }
      let(:moves) do
        offenders.map { |o| o.fetch(:prisonerNumber) }
      end
      let(:summary_offenders) { assigns(:offenders) }

      render_views

      before do
        stub_offenders_for_prison(prison, offenders)
        stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN")
          .with(body: moves.to_json)
          .to_return(body: moves.map { |offender_no| attributes_for(:movement, offenderNo: offender_no, toAgency: prison, movementDate: Date.new(2018, 10, 1).to_s) }.to_json)
      end

      it 'gets page 1 by default' do
        get :missing_information, params: { prison_id: prison }

        expect(summary_offenders.size).to eq(50)
        expect(summary_offenders.current_page).to eq(1)
        expect(summary_offenders.total_pages).to eq(3)
      end

      it 'gets page 2' do
        get :missing_information, params: { prison_id: prison, page: 2 }

        expect(summary_offenders.size).to eq(50)
        expect(summary_offenders.current_page).to eq(2)
        expect(summary_offenders.total_pages).to eq(3)
      end

      it 'gets page 3' do
        get :missing_information, params: { prison_id: prison, page: 3 }

        expect(summary_offenders.size).to eq(20)
        expect(summary_offenders.current_page).to eq(3)
        expect(summary_offenders.total_pages).to eq(3)
      end
    end

    context 'when sorting' do
      context 'with allocated offenders' do
        let(:prison) { create(:prison, code: 'BXI').code }

        it 'handles trying to sort by missing field for allocated offenders' do
          # Allocated offenders do have to have their prison_arrival_date even if they don't use it
          # because we now need it to calculate the totals.
          stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN")
            .to_return(body: [].to_json)

          # When viewing allocated, cannot sort by awaiting_allocation_for as it is not available and is
          # meaningless in this context. We do not want to crash if passed a field that is not searchable
          # within a specific context.
          offender_id = 'G7514GW'
          offenders = [build(:nomis_offender, prisonerNumber: offender_id)]
          stub_offenders_for_prison(prison, offenders)

          create(:case_information, offender: build(:offender, nomis_offender_id: offender_id))
          create(:allocation_history, nomis_offender_id: offender_id, primary_pom_nomis_id: 234, prison: prison)

          get :allocated, params: { prison_id: prison, sort: 'awaiting_allocation_for asc' }
          expect(assigns(:offenders).count).to eq(1)
        end
      end

      context 'with unallocated offenders' do
        let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }
        let(:today_plus_7_weeks) { (Time.zone.today + 7.weeks).to_s }

        let(:offenders) do
          [

            build(:nomis_offender, prisonerNumber: "G7514GW", imprisonmentStatus: "LR"), # custody case
            build(:nomis_offender, prisonerNumber: "G1234VV", imprisonmentStatus: "SENT03",
                                   sentence: attributes_for(:sentence_detail, conditionalReleaseDate: today_plus_7_weeks)), # community case
            build(:nomis_offender, prisonerNumber: "G4234GG", imprisonmentStatus: "SENT03"), # custody case
            build(:nomis_offender, prisonerNumber: "G1234GY", imprisonmentStatus: "SENT03",
                                   sentence: attributes_for(:sentence_detail, sentenceStartDate: "2019-02-08",
                                                                              automaticReleaseDate: today_plus_13_weeks)) # community case
          ]
        end

        before do
          stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN")
            .to_return(body: [].to_json)

          offenders.each do |offender|
            create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
          end
        end

        it 'can sort by case_owner in ascending order' do
          stub_offenders_for_prison(prison, offenders)

          get :unallocated, params: { prison_id: prison, sort: 'case_owner asc' }

          expect(assigns(:offenders).first.pom_supporting?).to eq(true)
          expect(assigns(:offenders).last.pom_responsible?).to eq(true)
        end

        it 'can sort by case owner in descending order' do
          stub_offenders_for_prison(prison, offenders)

          get :unallocated, params: { prison_id: prison, sort: 'case_owner desc' }
          expect(assigns(:offenders).first.pom_responsible?).to eq(true)
          expect(assigns(:offenders).last.pom_supporting?).to eq(true)
        end
      end
    end

    describe '#search' do
      let(:nomis_staff_id) { 485_926 }

      let(:poms) do
        [
          build(:pom,
                firstName: 'Alice',
                lastName: 'Ward',
                position: RecommendationService::PRISON_POM,
                staffId: nomis_staff_id
               )
        ]
      end

      before do
        stub_poms(prison, poms)
        stub_signed_in_pom(prison, nomis_staff_id)
      end

      context 'when user is an SPO' do
        before do
          stub_sso_data(prison)
        end

        it 'can search' do
          offenders = build_list(:nomis_offender, 1)
          stub_offenders_for_prison(prison, offenders)

          get :search, params: { prison_id: prison, q: 'Cal' }
          expect(response.status).to eq(200)
          expect(response).to be_successful

          expect(assigns(:q)).to eq('Cal')
          expect(assigns(:offenders).size).to eq(0)
        end

        context "with 3 offenders", :allocation do
          let(:first_offender) { build(:nomis_offender, firstName: 'Alice', lastName: 'Bloggs') }
          let(:first_offender_no) { first_offender.fetch(:prisonerNumber) }
          let(:offenders) { build_list(:nomis_offender, 2, lastName: 'Bloggs') }
          let(:updated_offenders) { assigns(:offenders) }
          # This offender is the one with an allocation - created below
          let(:alloc_offender) { updated_offenders.detect { |o| o.offender_no == first_offender_no } }

          before do
            stub_offenders_for_prison(prison, [first_offender] + offenders)
            PomDetail.create(prison_code: prison, nomis_staff_id: nomis_staff_id, working_pattern: 1.0, status: 'active')

            ([first_offender] + offenders).each { |o| create(:case_information, offender: build(:offender, nomis_offender_id: o.fetch(:prisonerNumber))) }
            create(:allocation_history,
                   prison: prison,
                   nomis_offender_id: first_offender_no,
                   primary_pom_name: 'Alice Ward',
                   primary_pom_allocated_at: allocated_date,
                   primary_pom_nomis_id: nomis_staff_id)
          end

          context "with a date" do
            let(:allocated_date) { Time.zone.now.utc }

            it 'gets the POM names for allocated offenders' do
              get :search, params: { prison_id: prison, q: 'Blog' }

              expect(updated_offenders.count).to eq(3)
              expect(alloc_offender.formatted_pom_name).to eq('Alice Ward')
              expect(alloc_offender.allocation_date).to be_a(Date)
            end

            it 'can find all the Alices' do
              get :search, params: { prison_id: prison, q: 'Alice' }

              expect(updated_offenders.count).to eq(1)
            end
          end

          context "when 'primary_pom_allocated_at' date is nil" do
            let(:allocated_date) { Time.zone.now.utc }

            it "uses 'updated_at' date when 'primary_pom_allocated_at' date is nil" do
              get :search, params: { prison_id: prison, q: 'Blog' }

              expect(alloc_offender.formatted_pom_name).to eq('Alice Ward')
              expect(alloc_offender.allocation_date).to be_a(Date)
            end
          end
        end
      end
    end

    describe '#show' do
      let(:offender) { build(:nomis_offender, prisonId: prison) }
      let(:offender_no) { offender.fetch(:prisonerNumber) }
      let(:page) { Nokogiri::HTML(response.body) }

      context 'when an offender has a previous LAYER_3 OASys assessments' do
        let(:completed_date) { '2021-06-02'.to_date }

        before do
          expect(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_latest_oasys_date).with(offender_no).and_return(assessment_type: 'LAYER_3', completed: completed_date)
          stub_offender(offender)
          stub_keyworker prison, offender_no, build(:keyworker)

          get :show, params: { prison_id: prison, id: offender_no }
          expect(page.css('#oasys-date')).to have_text('Last completed OASys')
        end

        render_views

        it 'displays the latest one' do
          expect(assigns(:oasys_assessment)).to eq(assessment_type: 'LAYER_3', completed: completed_date)
          expect(page.css('#oasys-date')).to have_text("02 Jun 2021")
        end
      end

      context 'when an offender has a previous LAYER_1 OASys assessments' do
        let(:completed_date) { '2021-06-02'.to_date }

        before do
          expect(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_latest_oasys_date).with(offender_no).and_return(assessment_type: 'LAYER_1', completed: completed_date)
          stub_offender(offender)
          stub_keyworker prison, offender_no, build(:keyworker)

          get :show, params: { prison_id: prison, id: offender_no }
          expect(page.css('#oasys-date')).to have_text('Last completed OASys')
        end

        render_views

        it 'displays the latest one' do
          expect(assigns(:oasys_assessment)).to eq(assessment_type: 'LAYER_1', completed: completed_date)
          expect(page.css('#oasys-date')).to have_text("02 Jun 2021")
        end
      end

      context 'when an offender has no OASys assessments' do
        let(:completed_date) { nil }

        before do
          expect(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_latest_oasys_date).with(offender_no).and_return(nil)
          stub_offender(offender)
          stub_keyworker prison, offender_no, build(:keyworker)

          get :show, params: { prison_id: prison, id: offender_no }
          expect(page.css('#oasys-date')).to have_text('Last completed OASys')
        end

        render_views

        it 'displays a reason for no date being present' do
          expect(assigns(:oasys_assessment)).to eq(nil)
          expect(page.css('#oasys-date')).to have_text 'No OASys information'
        end
      end
    end
  end

  describe 'when an allocation exists but is not active (no primary pom allocated)' do
    it 'can still render the page' do
      prison = create(:prison)
      offender = build(:nomis_offender, prisonId: prison.code)
      offender_id = offender[:prisonerNumber]

      stub_offender(offender)
      stub_keyworker prison.code, offender_id, build(:keyworker)
      stub_sso_data(prison.code)

      allow(PrisonOffenderManagerService).to receive(:fetch_pom_name).with(nil).and_raise(Faraday::ResourceNotFound, "the server responded with status 404")
      allow(PrisonOffenderManagerService).to receive(:fetch_pom_name).with(222_888).and_return('Secondary Pom')

      create(:allocation_history, nomis_offender_id: offender_id, secondary_pom_name: 'Secondary Pom', secondary_pom_nomis_id: 222_888, prison: prison.code, primary_pom_nomis_id: nil, primary_pom_name: nil)

      get :show, params: { prison_id: prison.code, id: offender_id }

      expect(response.status).to be(200)
      expect(assigns(:primary_pom_name)).to be_nil
      expect(assigns(:secondary_pom_name)).to eq('Secondary Pom')
    end
  end
end
