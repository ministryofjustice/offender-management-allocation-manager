require 'rails_helper'

feature 'when NOMIS is missing information' do
  let(:prison_code) { 'LEI' }
  let(:offender_no) { 'A1' }
  let(:stub_keyworker_host) { Rails.configuration.keyworker_api_host }
  let(:staff_id) { 111_111 }
  let(:booking_id) { 3 }

  before do
    stub_sentence_type(booking_id)
  end

  context 'when logged in as a POM' do
    before do
      user_name = 'example_user'
      stub_poms = [{ staffId: staff_id, position: RecommendationService::PRISON_POM }]

      stub_request(:post, "#{ApiHelper::T3_HOST}/auth/oauth/token").
        with(query: { grant_type: 'client_credentials' }).
        to_return(body: {}.to_json)

      stub_request(:get, "#{ApiHelper::T3}/users/example_user").
        to_return(body: { staffId: staff_id }.to_json)

      stub_request(:get, "#{ApiHelper::T3}/staff/#{staff_id}/emails").
        to_return(body: [].to_json)

      stub_request(:get, "#{ApiHelper::T3}/staff/roles/#{prison_code}/role/POM").
        to_return(body: stub_poms.to_json)

      signin_pom_user(user_name)
    end

    describe 'the caseload page' do
      context 'with an NPS offender with a determinate sentence, but no release dates' do
        before do
          stub_offenders = [build(:nomis_offender, offenderNo: offender_no,
                                  imprisonmentStatus: 'SEC91',
                                  sentence: build(:nomis_sentence_detail,
                                                  releaseDate: 30.years.from_now.iso8601,
                                 sentenceStartDate: Time.zone.now.iso8601))]

          stub_offenders_for_prison(prison_code, stub_offenders)

          create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)
          create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS')
        end

        it 'does not error' do
          visit prison_staff_caseload_index_path(prison_code, staff_id)

          expect(page).to have_content('Showing 1 - 1 of 1 results')
        end
      end
    end

    describe 'the prisoner page' do
      before do
        offender = build(:nomis_offender, offenderNo: offender_no, sentence: build(:nomis_sentence_detail, conditionalReleaseDate: Time.zone.today + 22.months))

        stub_request(:get, "#{ApiHelper::T3}/staff/#{staff_id}").
          to_return(body: { staffId: staff_id, firstName: "TEST", lastName: "MOIC" }.to_json)

        stub_request(:post, "#{ApiHelper::T3}/offender-assessments/CATEGORY").
          to_return(body: {}.to_json)

        stub_request(:get, "#{stub_keyworker_host}/key-worker/#{prison_code}/offender/#{offender_no}").
          to_return(body: {}.to_json)

        stub_offender(offender)

        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)
        create(:case_information, nomis_offender_id: offender_no, case_allocation: 'NPS')
      end

      it 'does not error' do
        visit prison_prisoner_path(prison_code, offender_no)

        expect(page).to have_content('Prisoner information')

        earliest_release_date = find('#earliest_release_date').text
        expect(Date.parse(earliest_release_date)).to eq(Time.zone.today + 22.months)
      end
    end

    describe 'the handover start page' do
      before do
        stub_offenders = [build(:nomis_offender, offenderNo: offender_no)]

        stub_offenders_for_prison(prison_code, stub_offenders)
      end

      it 'does not error' do
        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)

        visit prison_staff_caseload_handover_start_path(prison_code, staff_id)

        expect(page).to have_content('All cases for start of handover to the community in the next 30 days')
      end
    end
  end

  context 'when logged in as an SPO' do
    before do
      stub_request(:post, "#{ApiHelper::T3_HOST}/auth/oauth/token").
        with(query: { grant_type: 'client_credentials' }).
        to_return(body: {}.to_json)

      signin_spo_user('example_SPO')
      stub_request(:get, "#{ApiHelper::T3}/users/example_SPO").
          to_return(body: { 'staffId': 754_732 }.to_json)
      stub_request(:get, "#{ApiHelper::T3}/staff/754732/emails").
          to_return(body: [].to_json)
    end

    context 'with an NPS offender with an indeterminate sentence, but no release dates' do
      before do
        stub_offender = build(:nomis_offender, offenderNo: offender_no)

        stub_offenders_for_prison(prison_code, [stub_offender])

        stub_request(:get, "#{ApiHelper::T3}/prisoners/#{offender_no}").
          to_return(body: [stub_offender].to_json)

        stub_request(:post, "#{ApiHelper::T3}/offender-assessments/CATEGORY").
          to_return(body: {}.to_json)

        stub_request(:get, "#{ApiHelper::T3}/bookings/#{booking_id}/mainOffence").
          to_return(body: {}.to_json)

        stub_poms = [{ staffId: staff_id, position: RecommendationService::PRISON_POM }]

        stub_request(:get, "#{ApiHelper::T3}/staff/roles/#{prison_code}/role/POM").
          to_return(body: stub_poms.to_json)

        stub_request(:get, "#{ApiHelper::T3}/staff/#{staff_id}").
          to_return(body: {}.to_json)

        stub_request(:get, "#{ApiHelper::T3}/staff/#{staff_id}/emails").
          to_return(body: [].to_json)

        stub_request(:get, "#{stub_keyworker_host}/key-worker/#{prison_code}/offender/#{offender_no}").
          to_return(body: {}.to_json)

        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: staff_id)
        create(
          :case_information,
          nomis_offender_id: offender_no,
          case_allocation: 'NPS',
          welsh_offender: welsh
        )
      end

      describe 'the pom details page' do
        before { visit prison_pom_path(prison_code, staff_id) }

        context 'with a welsh offender' do
          let(:welsh) { 'Yes' }

          context 'with a sentence start date post-policy' do
            let(:sentence_start) { Time.zone.now }

            it 'shows their allocated case' do
              expect(page).to have_content(offender_no)
            end
          end

          context 'with a sentence start date pre-policy' do
            let(:sentence_start) { '01 Jan 2010'.to_date }

            it 'shows their allocated case' do
              expect(page).to have_content(offender_no)
            end
          end
        end

        context 'with an english offender' do
          let(:welsh) { 'No' }

          context 'with a sentence start date post-policy' do
            let(:sentence_start) { Time.zone.now }

            it 'shows their allocated case' do
              expect(page).to have_content(offender_no)
            end
          end

          context 'with a sentence start date pre-policy' do
            let(:sentence_start) { '01 Jan 2010'.to_date }

            it 'shows their allocated case' do
              expect(page).to have_content(offender_no)
            end
          end
        end
      end
    end
  end
end
