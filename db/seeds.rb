# Jay Heal
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_737,
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

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G7806VO',
  tier: 'A',
  case_allocation: 'NPS',
  omicable: 'Yes'
)

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G3462VT',
  tier: 'B',
  case_allocation: 'NPS',
  omicable: 'Yes'
)

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G3536UF',
  tier: 'C',
  case_allocation: 'CRC',
  omicable: 'No'
)

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G2911GD',
  tier: 'D',
  case_allocation: 'CRC',
  omicable: 'No'
)

CaseInformation.find_or_create_by!(
    nomis_offender_id: 'G7998GJ',
    tier: 'D',
    case_allocation: 'CRC',
    omicable: 'No'
)

AllocationService.create_or_update(
    nomis_offender_id: 'G7806VO',
    nomis_booking_id: 1_153_753,
    prison: 'LEI',
    allocated_at_tier: 'A',
    created_by_username: 'PK000223',
    primary_pom_nomis_id: 485_637,
    primary_pom_allocated_at: DateTime.now.utc,
    event: AllocationVersion::ALLOCATE_PRIMARY_POM,
    event_trigger: AllocationVersion::USER
  )

AllocationService.create_or_update(
  nomis_offender_id: 'G3462VT',
  nomis_booking_id: 1_153_753,
  prison: 'LEI',
  allocated_at_tier: 'B',
  created_by_username: 'PK000223',
  primary_pom_nomis_id: 485_737,
  event: AllocationVersion::ALLOCATE_PRIMARY_POM,
  event_trigger: AllocationVersion::USER
  )

AllocationService.create_or_update(
  nomis_offender_id: 'G7998GJ',
  nomis_booking_id: 1_153_753,
  prison: 'LEI',
  allocated_at_tier: 'D',
  created_by_username: 'PK000223',
  primary_pom_nomis_id: 485_833,
  event: AllocationVersion::ALLOCATE_PRIMARY_POM,
  event_trigger: AllocationVersion::USER
)
