# Jay Heal
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_833,
  status: 'active',
  working_pattern: 1
)

# Moic POM
PomDetail.find_or_create_by!(
  nomis_staff_id: 485_926,
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

ldu1 = LocalDivisionalUnit.find_or_create_by!(
    code: "WELDU",
    name: "Welsh LDU",
    email_address: "WalesNPS@example.com"
)

ldu2 = LocalDivisionalUnit.find_or_create_by!(
    code: "ENLDU",
    name: "English LDU",
    email_address: "EnglishNPS@example.com"
)

ldu3 = LocalDivisionalUnit.find_or_create_by!(
    code: "OTHERLDU",
    name: "English LDU 2",
    email_address: nil
)

team1 = Team.find_or_create_by!(
    code: "WELSH1",
    name: "NPS - Wales",
    shadow_code: "W01",
    local_divisional_unit: ldu1
)

team2 = Team.find_or_create_by!(
    code: "ENG1",
    name: "NPS - England",
    shadow_code: "E01",
    local_divisional_unit: ldu2
)

team3 = Team.find_or_create_by!(
    code: "ENG2",
    name: "NPS - England 2",
    shadow_code: "E02",
    local_divisional_unit: ldu3
)

# The offenders below are those with release dates a few years in the future and can therefore use the
# responsibility override workflow

CaseInformation.find_or_create_by!(nomis_offender_id: 'G7658UL') do |info|
  info.tier = 'A'
  info.case_allocation = 'NPS'
  info.welsh_offender = 'Yes'
  info.manual_entry =  true
  info.team_id = team1.id
  info.probation_service = "Wales"
end

CaseInformation.find_or_create_by!(nomis_offender_id: 'G7517GF') do |info|
  info.tier = 'B'
  info.case_allocation = 'NPS'
  info.welsh_offender = 'Yes'
  info.manual_entry = true
  info.team_id = team2.id
  info.probation_service = "Wales"
end

CaseInformation.find_or_create_by!(nomis_offender_id: 'G3536UF') do |info|
  info.tier = 'A'
  info.case_allocation = 'NPS'
  info.welsh_offender = 'No'
  info.manual_entry = true
  info.team_id = team2.id
  info.probation_service = "England"
end

CaseInformation.find_or_create_by!(nomis_offender_id: 'G2260UO') do |info|
  info.tier = 'B'
  info.case_allocation = 'NPS'
  info.welsh_offender = 'No'
  info.manual_entry = true
  info.team_id = team3.id
  info.probation_service = "England"
end
