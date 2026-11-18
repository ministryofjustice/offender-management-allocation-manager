require 'swagger_helper'

describe 'SAR API' do
  let(:Authorization) { 'Bearer TEST_TOKEN' }

  path '/subject-access-request' do
    get 'Retrieves all held info for offender' do
      security [{ Bearer: [] }]

      tags 'Subject Access Request'
      description(
        [
          '* A valid Bearer token must be supplied in the Authorization header.',
          '* NOMIS Prison Number (PRN) must be provided as part of the request.',
          '* Requests with neither identifier, or with both PRN and CRN, return HTTP code 400.',
          '* Dates must be valid calendar dates in YYYY-MM-DD format; invalid dates or a reversed range return HTTP code 400.',
          '* Provide both fromDate and toDate, or neither. An incomplete date range returns HTTP code 400.',
          '* The role ROLE_SAR_DATA_ACCESS is required',
          '* If the product uses the identifier type transmitted in the request, it can respond with its data and HTTP code 200',
          '* If the product uses the identifier type transmitted in the request but has no data to respond with, it should respond with HTTP code 204',
          '* If only a CRN is supplied, the endpoint returns HTTP code 209 with an empty response body.'
        ].join("\n")
      )

      produces 'application/json'
      consumes 'application/json'

      parameter name: :prn,
                in: :query,
                schema: { '$ref' => '#/components/schemas/NomsNumber' },
                description: 'NOMIS Prison Reference Number'
      parameter name: :crn,
                in: :query,
                type: :string,
                description: 'nDelius Case Reference Number. **Do not use this parameter for this endpoint**'
      parameter name: :fromDate,
                in: :query,
                schema: { type: :string, format: :date },
                description: 'Optional parameter denoting minimum date of event occurrence which should be returned in the response (if used, both dates must be provided)'
      parameter name: :toDate,
                in: :query,
                schema: { type: :string, format: :date },
                description: 'Optional parameter denoting maximum date of event occurrence which should be returned in the response (if used, both dates must be provided)'

      describe 'when not authorised' do
        let(:Authorization) { nil }

        response '401', 'Request is not authorised' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'Valid authorisation token required',
            errorCode: 1,
            status: 401,
            userMessage: 'Valid authorisation token required',
          }

          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end
      end

      describe 'when forbidden due to role' do
        before do
          stub_decoded_token(authorities: %w[ROLE_FOOBAR])
        end

        response '403', 'Invalid token role' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'Invalid token role',
            errorCode: 5,
            status: 403,
            userMessage: 'Invalid token role',
          }

          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end
      end

      describe 'when authorised' do
        before do
          allow_any_instance_of(Api::SarController).to receive(:verify_token)
        end

        response '400', 'Invalid request parameters' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :conflicting_identifiers, {
            developerMessage: 'PRN and CRN parameters passed',
            errorCode: 11,
            status: 400,
            userMessage: 'PRN and CRN parameters passed',
          }

          example 'application/json', :missing_identifiers, {
            developerMessage: 'PRN or CRN parameter required',
            errorCode: 12,
            status: 400,
            userMessage: 'PRN or CRN parameter required',
          }

          example 'application/json', :invalid_date, {
            developerMessage: 'Invalid date format',
            errorCode: 20,
            status: 400,
            userMessage: 'Invalid date format',
          }

          example 'application/json', :reversed_date_range, {
            developerMessage: 'fromDate must be on or before toDate',
            errorCode: 22,
            status: 400,
            userMessage: 'fromDate must be on or before toDate',
          }

          example 'application/json', :invalid_identifier_type, {
            developerMessage: 'PRN and CRN parameters must be strings',
            errorCode: 10,
            status: 400,
            userMessage: 'PRN and CRN parameters must be strings',
          }

          example 'application/json', :incomplete_date_range, {
            developerMessage: 'fromDate and toDate must be provided together',
            errorCode: 21,
            status: 400,
            userMessage: 'fromDate and toDate must be provided together',
          }

          let(:crn) { nil }
          let(:prn) { nil }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          before do
            expect(SarOffenderDataService).not_to receive(:new)
            expect(Rails.logger).not_to receive(:info).with(include('event=subject_access_request_success'))
          end

          context 'with both identifiers' do
            let(:crn) { '123456' }
            let(:prn) { 'A1111AA' }

            run_test! do |response|
              expect(JSON.parse(response.body)).to include('errorCode' => 11)
            end
          end

          context 'with neither identifier' do
            run_test! do |response|
              expect(JSON.parse(response.body)).to include('errorCode' => 12)
            end
          end

          context 'with empty identifiers' do
            let(:crn) { '' }
            let(:prn) { '' }

            run_test! do |response|
              expect(JSON.parse(response.body)).to include('errorCode' => 12)
            end
          end

          context 'with whitespace-only identifiers' do
            let(:crn) { ' ' }
            let(:prn) { ' ' }

            run_test! do |response|
              expect(JSON.parse(response.body)).to include('errorCode' => 12)
            end
          end

          %i[fromDate toDate].each do |date_parameter|
            ['apples',
             '17 Nov 2026',
             '2026-1-01',
             '2026-02-29',
             '2026-13-01',
             '2026-11-17T00:00:00Z',
             ' '].each do |value|
              context "with invalid #{date_parameter}: #{value.inspect}" do
                let(:prn) { 'A1111AA' }
                let(date_parameter) { value }

                run_test! do |response|
                  expect(JSON.parse(response.body)).to include('errorCode' => 20)
                end
              end
            end
          end

          context 'with an invalid date and an unsupported identifier' do
            let(:crn) { '123456' }
            let(:fromDate) { 'apples' }

            run_test! do |response|
              expect(JSON.parse(response.body)).to include('errorCode' => 20)
            end
          end

          context 'with a reversed date range' do
            let(:prn) { 'A1111AA' }
            let(:fromDate) { '2026-11-18' }
            let(:toDate) { '2026-11-17' }

            run_test! do |response|
              expect(JSON.parse(response.body)).to include('errorCode' => 22)
            end
          end

          {
            'only a start date' => ['2026-11-17', nil],
            'only an end date' => [nil, '2026-11-17'],
            'an empty end date' => ['2026-11-17', ''],
            'an empty start date' => ['', '2026-11-17'],
          }.each do |description, (from_date, to_date)|
            context "with #{description}" do
              let(:prn) { 'A1111AA' }
              let(:fromDate) { from_date }
              let(:toDate) { to_date }

              run_test! do |response|
                expect(JSON.parse(response.body)).to include('errorCode' => 21, 'status' => 400)
              end
            end
          end
        end

        describe 'successful request logging' do
          before do
            allow(Rails.logger).to receive(:info)
            service = instance_double(SarOffenderDataService, find: { nomsNumber: 'A1111AA' })
            allow(SarOffenderDataService).to receive(:new).and_return(service)
          end

          it 'logs the status, PRN and date range' do
            get '/subject-access-request', params: { prn: 'A1111AA', fromDate: '2026-11-01', toDate: '2026-11-17' }

            expect(response).to have_http_status(:ok)
            expect(Rails.logger).to have_received(:info).with(
              'event=subject_access_request_success,status=200,prn=A1111AA,from_date=2026-11-01,to_date=2026-11-17'
            ).once
          end

          it 'logs empty date fields when no date range is supplied' do
            get '/subject-access-request', params: { prn: 'A1111AA' }

            expect(response).to have_http_status(:ok)
            expect(Rails.logger).to have_received(:info).with(
              'event=subject_access_request_success,status=200,prn=A1111AA,from_date=,to_date='
            ).once
          end
        end

        describe 'structured query parameters' do
          { prn: 10, crn: 10, fromDate: 20, toDate: 20 }.each do |parameter, error_code|
            [['2026-11-17'], { value: '2026-11-17' }].each do |value|
              it "rejects #{parameter} supplied as #{value.class}" do
                expect(SarOffenderDataService).not_to receive(:new)

                get '/subject-access-request', params: { prn: 'A1111AA' }.merge(parameter => value)

                expect(response).to have_http_status(:bad_request)
                expect(JSON.parse(response.body)).to include('errorCode' => error_code, 'status' => 400)
              end
            end
          end
        end

        response '209', 'Unsupported identifier type (CRN); empty response body' do
          let(:crn) { '123456' }
          let(:prn) { nil }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          before do
            expect(SarOffenderDataService).not_to receive(:new)
          end

          run_test! do |response|
            expect(response.body).to be_empty
          end
        end

        response '204', 'Offender not found' do
          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          {
            'no dates' => [nil, nil],
            'empty dates' => ['', ''],
            'the same start and end date' => ['2026-11-17', '2026-11-17'],
            'a valid leap day' => ['2024-02-29', '2024-03-01'],
          }.each do |description, (from_date, to_date)|
            context "with #{description}" do
              let(:fromDate) { from_date }
              let(:toDate) { to_date }

              before do
                service = instance_double(SarOffenderDataService, find: nil)
                expect(SarOffenderDataService).to receive(:new)
                  .with(prn, from_date.presence && Date.iso8601(from_date), to_date.presence && Date.iso8601(to_date))
                  .and_return(service)
              end

              run_test! do |response|
                expect(response.body).to be_empty
              end
            end
          end

          context 'with no stored offender data' do
            run_test! do |response|
              expect(response.body).to be_empty
            end
          end
        end

        response '200', 'Offender found' do
          schema '$ref' => '#/components/schemas/SarOffenderData'

          before do
            create(:offender, nomis_offender_id: prn)
            create(:allocation_history, prison: 'LEI', nomis_offender_id: prn, primary_pom_name: 'OLD_NAME, MOIC')
            create(:audit_event, nomis_offender_id: prn)
            create(:calculated_handover_date, nomis_offender_id: prn)
            create(:case_information, nomis_offender_id: prn)
            create(:early_allocation, nomis_offender_id: prn)
            create(:email_history, :auto_early_allocation, nomis_offender_id: prn)
            create(:handover_progress_checklist, nomis_offender_id: prn)
            create(:offender_email_sent, nomis_offender_id: prn)
            create(:responsibility, nomis_offender_id: prn)
            create(:victim_liaison_officer, nomis_offender_id: prn)
          end

          context 'with no date range' do
            let(:crn) { nil }
            let(:prn) { 'G7266VD' }
            let(:fromDate) { nil }
            let(:toDate) { nil }

            run_test!
          end

          context 'with date range' do
            let(:crn) { nil }
            let(:prn) { 'G7266VD' }
            let(:fromDate) { (Time.zone.today - 1.day).to_s }
            let(:toDate) { (Time.zone.today + 1.day).to_s }

            run_test!
          end
        end
      end
    end
  end
end
