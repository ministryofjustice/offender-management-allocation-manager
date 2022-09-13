Feature: Handover Date Rules

  Scenario Outline: Determinate NPS Conditional Release Date Case
    Given a determinate NPS CRD case
    Given conditional release date is <crd_months> months <crd_days> days after sentence start date
    When community dates are calculated
    Then COM allocated date is set <com_alloc_months> months <com_alloc_days> days before conditional release date
    Then COM responsible date is set <com_resp_months> months <com_resp_days> days before conditional release date

    Scenarios:
      | crd_months | crd_days | com_alloc_months | com_alloc_days | com_resp_months | com_resp_days |
      | 7          | 15       | 7                | 15             | 7               | 15            |
      | 7          | 16       | 7                | 15             | 7               | 15            |
      | 7          | 14       | 7                | 14             | 7               | 14            |

  Scenario Outline: Determinate NPS Automatic Release Date Case
    Given a determinate NPS ARD case
    Given automatic release date is <ard_months> months <ard_days> days after sentence start date
    When community dates are calculated
    Then COM allocated date is set <com_alloc_months> months <com_alloc_days> days before automatic release date
    Then COM responsible date is set <com_resp_months> months <com_resp_days> days before automatic release date

    Scenarios:
      | ard_months | ard_days | com_alloc_months | com_alloc_days | com_resp_months | com_resp_days |
      | 7          | 15       | 7                | 15             | 7               | 15            |
      | 7          | 16       | 7                | 15             | 7               | 15            |
      | 7          | 14       | 7                | 14             | 7               | 14            |

  Scenario: Determinate NPS Case with both CRD and ARD uses earliest date
    Given a determinate NPS case
    Given conditional release date is 8 months 0 days after sentence start date
    Given automatic release date is 9 months 0 days after sentence start date
    When community dates are calculated
    Then COM allocated date is set 7 months 15 days before conditional release date
    Then COM responsible date is set 7 months 15 days before conditional release date
