# Jay Heal
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_833,
  status: 'active',
  working_pattern: 1
)

# Ross Jones
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_752,
  status: 'active',
  working_pattern: 0.2
)

# Dom Bull
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_572,
  status: 'active',
  working_pattern: 1
)

# Kath Pobee-Norris
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_637,
  status: 'active',
  working_pattern: 0.4
)

# Andrien Ricketts
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_833,
  status: 'active',
  working_pattern: 1
)

LocalDivisionalUnit.create!(
    code: "WELDU",
    name: "Welsh LDU",
    email_address: "WalesNPS@example.com"
)

LocalDivisionalUnit.create!(
    code: "ENLDU",
    name: "English LDU",
    email_address: "EnglishNPS@example.com"
)

LocalDivisionalUnit.create!(
    code: "OTHERLDU",
    name: "English LDU 2",
    email_address: nil
)

# The offenders below are those with release dates a few years in the future and can therefore use the
# responsibility override workflow

CaseInformation.find_or_create_by!(
    nomis_offender_id: 'G7658UL',
    tier: 'A',
    case_allocation: 'NPS',
    welsh_offender: 'Yes',
    manual_entry: true,
    local_divisional_unit_id: 1,
    team_id: 4
)

CaseInformation.find_or_create_by!(
    nomis_offender_id: 'G7517GF',
    tier: 'B',
    case_allocation: 'NPS',
    welsh_offender: 'Yes',
    manual_entry: true,
    local_divisional_unit_id: 1,
    team_id: 51
)

CaseInformation.find_or_create_by!(
    nomis_offender_id: 'G3536UF',
    tier: 'A',
    case_allocation: 'NPS',
    welsh_offender: 'No',
    manual_entry: true,
    local_divisional_unit_id: 2,
    team_id: 6
)

CaseInformation.find_or_create_by!(
    nomis_offender_id: 'G2260UO',
    tier: 'B',
    case_allocation: 'NPS',
    welsh_offender: 'No',
    manual_entry: true,
    local_divisional_unit_id: 3,
    team_id: 34
)