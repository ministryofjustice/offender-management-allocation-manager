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
  working_pattern: 0.6
)

# Dom Bull
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_572,
  status: 'active',
  working_pattern: 1
)

# Jenny Ducket
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_636,
  status: 'active',
  working_pattern: 0.6
)

# Toby Retallick
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_595,
  status: 'active',
  working_pattern: 1
)
AllocationService.create_allocation(
  nomis_offender_id: 'G4273GI',
  nomis_booking_id: 1_153_753,
  prison: 'LEI',
  allocated_at_tier: 'C',
  created_by_username: 'PK000223',
  nomis_staff_id: 485_595
  )

AllocationService.create_allocation(
  nomis_offender_id: 'G4273GI',
  nomis_booking_id: 1_153_753,
  prison: 'LEI',
  allocated_at_tier: 'A',
  created_by_username: 'PK000223',
  nomis_staff_id: 485_595
  )

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G7806VO',
  tier: 'A',
  case_allocation: 'NPS',
  omicable: 'Yes',
  prison: 'LEI'
)

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G3462VT',
  tier: 'B',
  case_allocation: 'NPS',
  omicable: 'Yes',
  prison: 'LEI'
)

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G3536UF',
  tier: 'C',
  case_allocation: 'CRC',
  omicable: 'No',
  prison: 'LEI'
)

CaseInformation.find_or_create_by!(
  nomis_offender_id: 'G2911GD',
  tier: 'D',
  case_allocation: 'CRC',
  omicable: 'No',
  prison: 'LEI'
)
