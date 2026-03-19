require 'rails_helper'

RSpec.configure do |config|
  config.openapi_root = Rails.root.join('').to_s
  config.openapi_specs = {
    'public/openapi.yml' => {
      openapi: '3.0.3',
      info: {
        title: 'MPC/MOIC API',
        version: 'v2',
      },
      servers: [
        {
          url: '{protocol}://{defaultHost}',
          variables: {
            protocol: {
              default: :https
            },
            defaultHost: {
              default: 'dev.moic.service.justice.gov.uk'
            }
          }
        },
      ],
      components: {
        securitySchemes: {
          Bearer: {
            type: "apiKey",
            description: "A bearer token obtained from HMPPS SSO",
            name: "Authorization",
            in: "header",
          }
        },
        schemas: {
          NomsNumber: {
            type: "string",
            pattern: "^[A-Z]\\d{4}[A-Z]{2}",
            example: "G0862VO",
          },
          Status: {
            type: "object",
            additionalProperties: false,
            properties: {
              status: { type: "string" },
              message: { type: "string" },
            },
          },
          SarError: {
            required: %w[developerMessage errorCode status userMessage],
            type: :object,
            additionalProperties: false,
            properties: {
              developerMessage: { type: :string },
              errorCode: { type: :integer },
              status: { type: :integer },
              userMessage: { type: :string }
            }
          },
          SarAllocationHistoryItem: {
            type: :object,
            additionalProperties: false,
            required: %w[
              allocatedAtRosh
              allocatedAtTier
              createdAt
              createdByLastname
              event
              eventTrigger
              message
              overrideDetail
              overrideReasons
              primaryPomAllocatedAt
              prison
              recommendedPomType
              suitabilityDetail
              updatedAt
            ],
            properties: {
              allocatedAtRosh: { type: :string, nullable: true },
              allocatedAtTier: { type: :string, nullable: true },
              createdAt: { type: :string },
              createdByLastname: { type: :string, nullable: true },
              event: { type: :string, nullable: true },
              eventTrigger: { type: :string, nullable: true },
              message: { type: :string, nullable: true },
              overrideDetail: { type: :string, nullable: true },
              overrideReasons: { type: :string, nullable: true },
              primaryPomAllocatedAt: { type: :string, nullable: true },
              prison: { type: :string, nullable: true },
              recommendedPomType: { type: :string, nullable: true },
              suitabilityDetail: { type: :string, nullable: true },
              updatedAt: { type: :string },
            }
          },
          SarCalculatedEarlyAllocationStatus: {
            type: :object,
            nullable: true,
            additionalProperties: false,
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
          SarCalculatedHandoverDate: {
            type: :object,
            nullable: true,
            additionalProperties: false,
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
          SarCaseInformation: {
            type: :object,
            nullable: true,
            additionalProperties: false,
            required: %w[
              tier
              mappaLevel
              manualEntry
              probationService
              teamName
              localDeliveryUnit
              activeVlo
              enhancedResourcing
              roshLevel
              createdAt
              updatedAt
            ],
            properties: {
              tier: { type: :string, nullable: true },
              mappaLevel: { type: :integer, nullable: true },
              manualEntry: { type: :boolean },
              probationService: { type: :string, nullable: true },
              teamName: { type: :string, nullable: true },
              localDeliveryUnit: { type: :string, nullable: true },
              activeVlo: { type: :boolean },
              enhancedResourcing: { type: :boolean, nullable: true },
              roshLevel: { type: :string, nullable: true },
              createdAt: { type: :string },
              updatedAt: { type: :string },
            }
          },
          SarEarlyAllocationItem: {
            type: :object,
            additionalProperties: false,
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
              createdWithinReferralWindow
              outcome
              createdAt
              updatedAt
              createdByLastname
              updatedByLastname
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
              createdWithinReferralWindow: { type: :boolean },
              outcome: { type: :string },
              createdAt: { type: :string },
              updatedAt: { type: :string },
              createdByLastname: { type: :string, nullable: true },
              updatedByLastname: { type: :string, nullable: true },
            }
          },
          SarHandoverProgressChecklist: {
            type: :object,
            nullable: true,
            additionalProperties: false,
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
          SarResponsibility: {
            type: :object,
            nullable: true,
            additionalProperties: false,
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
          SarOffenderData: {
            required: %w[content],
            type: :object,
            additionalProperties: false,
            properties: {
              content: {
                type: :object,
                additionalProperties: false,
                required: %w[
                  nomsNumber
                  allocationHistory
                  calculatedEarlyAllocationStatus
                  calculatedHandoverDate
                  caseInformation
                  earlyAllocations
                  handoverProgressChecklist
                  responsibility
                ],
                properties: {
                  nomsNumber: { type: :string },
                  allocationHistory: {
                    type: :array,
                    items: { '$ref' => '#/components/schemas/SarAllocationHistoryItem' }
                  },
                  calculatedEarlyAllocationStatus: { '$ref' => '#/components/schemas/SarCalculatedEarlyAllocationStatus' },
                  calculatedHandoverDate: { '$ref' => '#/components/schemas/SarCalculatedHandoverDate' },
                  caseInformation: { '$ref' => '#/components/schemas/SarCaseInformation' },
                  earlyAllocations: {
                    type: :array,
                    items: { '$ref' => '#/components/schemas/SarEarlyAllocationItem' }
                  },
                  handoverProgressChecklist: { '$ref' => '#/components/schemas/SarHandoverProgressChecklist' },
                  responsibility: { '$ref' => '#/components/schemas/SarResponsibility' }
                }
              }
            }
          },
        },
      },
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
