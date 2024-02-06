require 'swagger_helper'

describe 'SAR API' do
  let(:Authorization) { 'Bearer TEST_TOKEN' }

  path '/subject-access-request' do
    get 'Retrieves all held info for offender' do
      produces 'application/json'
      consumes 'application/json'
      parameter name: :prn, in: :query, type: :string

      describe 'when not authorised' do
        response '401', 'Request is not authorised' do
          security [Bearer: []]
          schema '$ref' => '#/components/schemas/Status'

          let(:prn) { 'A1111AA' }
          run_test!
        end
      end

      describe 'when authorised' do
        before do
          allow_any_instance_of(Api::SarController).to receive(:verify_token)
        end

        response '200', 'Offender is found' do
          security [Bearer: []]
          schema required: %w[content],
                 type: :object,
                 properties: {
                   content: {
                     type: :object,
                     required: %w[
                       nomsNumber
                       auditEvents
                       calculatedEarlyAllocationStatus
                       calculatedHandoverDate
                       caseInformation
                       earlyAllocations
                       emailHistories
                       handoverProgressChecklist
                       offenderEmailSent
                       paroleRecord
                       paroleReviewImports
                       responsibility
                       victimLiaisonOfficers
                     ],
                     properties: {
                       nomsNumber: { type: :string },
                       allocationHistory: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             prison
                             allocatedAtTier
                             overrideReasons
                             overrideDetail
                             message
                             suitabilityDetail
                             primaryPomName
                             secondaryPomName
                             createdByName
                             primaryPomNomisId
                             secondaryPomNomisId
                             event
                             eventTrigger
                             primaryPomAllocatedAt
                             recommendedPomType
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             prison: { type: :string, nullable: true },
                             allocatedAtTier: { type: :string, nullable: true },
                             overrideReasons: { type: :string, nullable: true },
                             overrideDetail: { type: :string, nullable: true },
                             message: { type: :string, nullable: true },
                             suitabiltyDetail: { type: :string, nullable: true },
                             primaryPomName: { type: :string, nullable: true },
                             secondaryPomName: { type: :string, nullable: true },
                             createdByName: { type: :string, nullable: true },
                             primaryPomNomisId: { type: :integer, nullable: true },
                             secondaryPomNomisId: { type: :integer, nullable: true },
                             event: { type: :string, nullable: true },
                             eventTrigger: { type: :string, nullable: true },
                             primaryPomAllocatedAt: { type: :string, nullable: true },
                             recommendedPomType: { type: :string, nullable: true },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       },
                       auditEvents: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             tags
                             publishedAt
                             systemEvent
                             username
                             userHumanName
                             data
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             tags: {
                               type: :array,
                               items: { type: :string },
                             },
                             publishedAt: { type: :string },
                             systemEvent: { type: :boolean, nullable: true },
                             username: { type: :string, nullable: true },
                             userHumanName: { type: :string, nullable: true },
                             data: { type: :json },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       },
                       calculatedEarlyAllocationStatus: {
                         type: :object,
                         required: %w[
                           eligible
                           createdAt
                           updatedAt
                         ],
                         properties: {
                           eligible: { type: :boolean },
                           createdAt: { type: :string },
                           updatedAt: { type: :string },
                         }
                       },
                       calculatedHandoverDate: {
                         type: :object,
                         required: %w[
                           startDate
                           handoverDate
                           responsibility
                           lastCalculatedAt
                           reason
                           createdAt
                           updatedAt
                         ],
                         properties: {
                           startDate: { type: :string, nullable: true },
                           handoverDate: { type: :string, nullable: true },
                           responsibility: { type: :string },
                           lastCalculatedAt: { type: :string, nullable: true },
                           reason: { type: :string },
                           createdAt: { type: :string },
                           updatedAt: { type: :string },
                         }
                       },
                       caseInformation: {
                         type: :object,
                         required: %w[tier
                                      crn
                                      mappaLevel
                                      manualEntry
                                      probationService
                                      comName
                                      teamName
                                      localDeliveryUnitId
                                      lduCode
                                      comEmail
                                      activeVlo
                                      enhancedResourcing
                                      createdAt
                                      updatedAt],
                         properties: {
                           tier: { type: :string, nullable: true },
                           crn: { type: :string, nullable: true },
                           mappaLevel: { type: :integer, nullable: true },
                           manualEntry: { type: :boolean },
                           probationService: { type: :string, nullable: true },
                           comName: { type: :string, nullable: true },
                           teamName: { type: :string, nullable: true },
                           localDeliveryUnitId: { type: :integer, nullable: true },
                           lduCode: { type: :string, nullable: true },
                           comEmail: { type: :string, nullable: true },
                           activeVlo: { type: :boolean },
                           enhancedResourcing: { type: :boolean, nullable: true },
                           createdAt: { type: :string },
                           updatedAt: { type: :string },
                         }
                       },
                       earlyAllocations: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             oasysRiskAssessmentDate
                             convictedUnderTerrorisomAct2000
                             highProfile
                             seriousCrimePreventionOrder
                             mappaLevel3
                             cppcCase
                             highRiskOfSeriousHarm
                             mappaLevel2
                             pathfinderProcess
                             otherReason
                             extremismSeparation
                             dueForReleaseInLessThan24months
                             approved
                             reason
                             communityDecision
                             prison
                             createdByFirstname
                             createdByLastname
                             updatedByFirstname
                             updatedByLastname
                             createdWithinReferralWindow
                             outcome
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             oasysRiskAssessmentDate: { type: :string },
                             convictedUnderTerrorisomAct2000: { type: :boolean },
                             highProfile: { type: :boolean },
                             seriousCrimePreventionOrder: { type: :boolean },
                             mappaLevel3: { type: :boolean },
                             cppcCase: { type: :boolean },
                             highRiskOfSeriousHarm: { type: :boolean, nullable: true },
                             mappaLevel2: { type: :boolean, nullable: true },
                             pathfinderProcess: { type: :boolean, nullable: true },
                             otherReason: { type: :boolean, nullable: true },
                             extremismSeparation: { type: :boolean, nullable: true },
                             dueForReleaseInLessThan24months: { type: :boolean, nullable: true },
                             approved: { type: :boolean, nullable: true },
                             reason: { type: :string, nullable: true },
                             communityDecision: { type: :boolean, nullable: true },
                             prison: { type: :string, nullable: true },
                             createdByFirstname: { type: :string, nullable: true },
                             createdByLastname: { type: :string, nullable: true },
                             updatedByFirstname: { type: :string, nullable: true },
                             updatedByLastname: { type: :string, nullable: true },
                             createdWithinReferralWindow: { type: :boolean },
                             outcome: { type: :string },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       },
                       emailHistories: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             prison
                             name
                             email
                             event
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             prison: { type: :string },
                             name: { type: :string },
                             email: { type: :string },
                             event: { type: :string },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       },
                       handoverProgressChecklist: {
                         type: :object,
                         required: %w[
                           reviewedOasys
                           contactedCom
                           attendedHandoverMeeting
                           sentHandoverReport
                           createdAt
                           updatedAt
                         ],
                         properties: {
                           reviewedOasys: { type: :boolean },
                           contactedCom: { type: :boolean },
                           attendedHandoverMeeting: { type: :boolean },
                           sentHandoverReport: { type: :boolean },
                           createdAt: { type: :string },
                           updatedAt: { type: :string },
                         }
                       },
                       offenderEmailSent: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             staffMemberId
                             offenderEmailType
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             staffMemberId: { type: :string },
                             offenderEmailType: { type: :string },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       },
                       paroleRecord: {
                         type: :object,
                         required: %w[
                           paroleReviewDate
                           createdAt
                           updatedAt
                         ],
                         properties: {
                           paroleReviewDate: { type: :string },
                           createdAt: { type: :string },
                           updatedAt: { type: :string },
                         }
                       },
                       paroleReviewImports: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             title
                             prisonNo
                             sentenceType
                             sentenceDate
                             tariffExp
                             reviewDate
                             reviewId
                             reviewMilestoneDateId
                             reviewType
                             reviewStatus
                             currTargetDate
                             ms13TargetDate
                             ms13CompletionDate
                             finalResult
                             snapshotDate
                             rowNumber
                             importId
                             singleDaySnapshot
                             processedOn
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             title: { type: :string, nullable: true },
                             prisonNo: { type: :string, nullable: true },
                             sentenceType: { type: :string, nullable: true },
                             sentenceDate: { type: :string, nullable: true },
                             tariffExp: { type: :string, nullable: true },
                             reviewDate: { type: :string, nullable: true },
                             reviewId: { type: :string, nullable: true },
                             reviewMilestoneDateId: { type: :string, nullable: true },
                             reviewType: { type: :string, nullable: true },
                             reviewStatus: { type: :string, nullable: true },
                             currTargetDate: { type: :string, nullable: true },
                             ms13TargetDate: { type: :string, nullable: true },
                             ms13CompletionDate: { type: :string, nullable: true },
                             finalResult: { type: :string, nullable: true },
                             snapshotDate: { type: :string, nullable: true },
                             rowNumber: { type: :integer, nullable: true },
                             importId: { type: :string, nullable: true },
                             singleDaySnapshot: { type: :boolean, nullable: true },
                             processedOn: { type: :string, nullable: true },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       },
                       responsibility: {
                         type: :object,
                         required: %w[
                           reason
                           reasonText
                           value
                           createdAt
                           updatedAt
                         ],
                         properties: {
                           reason: { type: :string },
                           reasonText: { type: :string, nullable: true },
                           value: { type: :string },
                           createdAt: { type: :string },
                           updatedAt: { type: :string },
                         }
                       },
                       victimLiaisonOfficers: {
                         type: :array,
                         items: {
                           type: :object,
                           required: %w[
                             firstName
                             lastName
                             email
                             createdAt
                             updatedAt
                           ],
                           properties: {
                             firstName: { type: :string },
                             lastName: { type: :string },
                             email: { type: :string },
                             createdAt: { type: :string },
                             updatedAt: { type: :string },
                           }
                         }
                       }
                     }
                   }
                 }

          let(:prn) { 'G7266VD' }

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
            OffenderEmailSent.create(nomis_offender_id: prn, staff_member_id: 'ABC123', offender_email_type: 'handover_date')
            create(:parole_record, nomis_offender_id: prn)
            ParoleReviewImport.create(nomis_id: prn, title: 'Foo', import_id: 'abc123')
            create(:responsibility, nomis_offender_id: prn)
            create(:victim_liaison_officer, nomis_offender_id: prn)
          end

          run_test!
        end
      end
    end
  end
end
