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
          '* The role ROLE_SAR_DATA_ACCESS is required',
          '* If the product uses the identifier type transmitted in the request, it can respond with its data and HTTP code 200',
          '* If the product uses the identifier type transmitted in the request but has no data to respond with, it should respond with HTTP code 204',
          '* If the product does not use the identifier type transmitted in the request, it should respond with HTTP code 209'
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
                type: :string,
                description: 'Optional parameter denoting minimum date of event occurrence which should be returned in the response (if used, both dates must be provided)'
      parameter name: :toDate,
                in: :query,
                type: :string,
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

        response '400', 'PRN and CRN parameters passed' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'PRN and CRN parameters passed',
            errorCode: 2,
            status: 400,
            userMessage: 'PRN and CRN parameters passed',
          }

          let(:crn) { '123456' }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end

        response '209', 'CRN parameter not allowed' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'CRN parameter not allowed',
            errorCode: 3,
            status: 209,
            userMessage: 'CRN parameter not allowed',
          }

          let(:crn) { '123456' }
          let(:prn) { nil }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end

        response '210', 'Invalid date format' do
          schema '$ref' => '#/components/schemas/SarError'

          example 'application/json', :error_example, {
            developerMessage: 'Invalid date format',
            errorCode: 4,
            status: 210,
            userMessage: 'Invalid date format',
          }

          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { 'apples' }
          let(:toDate) { 'pears' }

          run_test!
        end

        response '204', 'Offender not found' do
          let(:crn) { nil }
          let(:prn) { 'A1111AA' }
          let(:fromDate) { nil }
          let(:toDate) { nil }

          run_test!
        end

        response '200', 'Offender found' do
          schema '$ref' => '#/components/schemas/SarOffenderData'

          before do
            create(:offender, nomis_offender_id: prn)
            create(:allocation_history, prison: 'LEI', nomis_offender_id: prn, primary_pom_name: 'OLD_NAME, MOIC')
            create(:audit_event, nomis_offender_id: prn)
            create(:calculated_early_allocation_status, nomis_offender_id: prn)
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
