# Jay Heal
PrisonOffenderManager.find_or_create_by!(
  nomis_staff_id: 485_737,
  status: 'active',
  working_pattern: 1
)

# Ross Jones
PrisonOffenderManager.find_or_create_by!(
  nomis_staff_id: 485_752,
  status: 'active',
  working_pattern: 0.5
)

# Dom Bull
PrisonOffenderManager.find_or_create_by!(
  nomis_staff_id: 485_572,
  status: 'active',
  working_pattern: 1
)

# Jenny Ducket
PrisonOffenderManager.find_or_create_by!(
  nomis_staff_id: 485_636,
  status: 'active',
  working_pattern: 0.5
)

# Toby Retallick
PrisonOffenderManager.find_or_create_by!(
  nomis_staff_id: 485_595,
  status: 'active',
  working_pattern: 1
)
AllocationService.create_allocation(
  nomis_offender_id: 'G4273GI',
  nomis_booking_id: 1_153_753,
  prison: 'LEI',
  allocated_at_tier: 'C',
  created_by: 'user@username.com',
  nomis_staff_id: 485_595
  )

AllocationService.create_allocation(
  nomis_offender_id: 'G4273GI',
  nomis_booking_id: 1_153_753,
  prison: 'LEI',
  allocated_at_tier: 'A',
  created_by: 'user@username.com',
  nomis_staff_id: 485_595
  )
