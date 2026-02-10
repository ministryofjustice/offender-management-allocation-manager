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
            properties: {
              status: { type: "string" },
              message: { type: "string" },
            },
          },
          SarError: {
            required: %w[developerMessage errorCode status userMessage],
            type: :object,
            properties: {
              developerMessage: { type: :string },
              errorCode: { type: :integer },
              status: { type: :integer },
              userMessage: { type: :string }
            }
          },
          SarOffenderData: {
            required: %w[content],
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
                  handoverProgressChecklist
                  offenderEmailSent
                  responsibility
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
                        primaryPomLastName
                        secondaryPomLastName
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
                        suitabilityDetail: { type: :string, nullable: true },
                        primaryPomLastName: { type: :string, nullable: true },
                        secondaryPomLastName: { type: :string, nullable: true },
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
                        createdAt: { type: :string },
                        updatedAt: { type: :string },
                      }
                    }
                  },
                  calculatedEarlyAllocationStatus: {
                    type: :object,
                    nullable: true,
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
                    nullable: true,
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
                    nullable: true,
                    required: %w[tier
                                 mappaLevel
                                 manualEntry
                                 probationService
                                 teamName
                                 localDeliveryUnit
                                 activeVlo
                                 enhancedResourcing
                                 createdAt
                                 updatedAt],
                    properties: {
                      tier: { type: :string, nullable: true },
                      mappaLevel: { type: :integer, nullable: true },
                      manualEntry: { type: :boolean },
                      probationService: { type: :string, nullable: true },
                      teamName: { type: :string, nullable: true },
                      localDeliveryUnit: { type: :string, nullable: true },
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
                        createdWithinReferralWindow: { type: :boolean },
                        outcome: { type: :string },
                        createdAt: { type: :string },
                        updatedAt: { type: :string },
                      }
                    }
                  },
                  handoverProgressChecklist: {
                    type: :object,
                    nullable: true,
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
                        offenderEmailType
                        createdAt
                        updatedAt
                      ],
                      properties: {
                        offenderEmailType: { type: :string },
                        createdAt: { type: :string },
                        updatedAt: { type: :string },
                      }
                    }
                  },
                  responsibility: {
                    type: :object,
                    nullable: true,
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
                  }
                }
              }
            }
          }
        },
      },
      paths: {}
    }
  }

  config.openapi_format = :yaml
end
