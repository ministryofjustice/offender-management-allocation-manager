Feature: NPS Determinate CRD or ARD Handover Date Rules

  Scenario Outline: NPS Determinate CRD Case
    Given a determinate NPS CRD case
    Given CRD is <crd_months> months <crd_days> days after sentence start
    When handover is calculated
    Then handover date is <handover_months> months <handover_days> days before CRD
    Then reason is nps_determinate

    Scenarios:
      | crd_months | crd_days | handover_months | handover_days |
      | 7          | 15       | 7               | 15            |
      | 7          | 16       | 7               | 15            |
      | 7          | 14       | 7               | 14            |

  Scenario Outline: Determinate NPS ARD Case
    Given a determinate NPS ARD case
    Given ARD is <ard_months> months <ard_days> days after sentence start
    When handover is calculated
    Then handover date is <handover_months> months <handover_days> days before ARD
    Then reason is nps_determinate

    Scenarios:
      | ard_months | ard_days | handover_months | handover_days |
      | 7          | 15       | 7               | 15            |
      | 7          | 16       | 7               | 15            |
      | 7          | 14       | 7               | 14            |

  Scenario: NPS Determinate Case with both CRD and ARD uses the earlier date
    Given a determinate NPS case
    Given CRD is 8 months 0 days after sentence start
    Given ARD is 9 months 0 days after sentence start
    When handover is calculated
    Then handover date is 7 months 15 days before CRD
    Then reason is nps_determinate
