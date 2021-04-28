# This mock/test data (prisons + LDUs) is for developers only - so that they have data to fall back on if they run db:reset
# It should not be run in production only in development environment and Heroku

Prison.find_or_create_by!(
  prison_type: 'womens',
  code: 'BZI',
  name: 'HMP Bronzefield',

                          )
Prison.find_or_create_by!(
  prison_type: 'mens_closed',
  code: 'LEI',
  name: 'HMP Leeds',

  )

Prison.find_or_create_by!(
  prison_type: 'mens_open',
  code: 'HDI',
  name: 'HMP/YOI Hatfield',

  )

ldu1 = LocalDeliveryUnit.find_or_create_by!(
  code: 'WELDU',
  name: 'Welsh LDU',
  email_address: 'WalesNPS@example.com',
  country: 'Wales',
  enabled: true
)

ldu2 = LocalDeliveryUnit.find_or_create_by!(
  code: 'ENLDU',
  name: 'English LDU',
  email_address: 'EnglishNPS@example.com',
  country: 'England',
  enabled: true
)

ldu3 = LocalDeliveryUnit.find_or_create_by!(
  code: "OTHERLDU",
  name: "English LDU 2",
  email_address: 'AnotherEnglishNPS@example.com',
  country: 'England',
  enabled: true
)

# TODO: Change these CaseInformation records to use 'new' LDUs once the 'old' are removed
# The offenders below are those with release dates a few years in the future and can therefore use the
# responsibility override workflow

CaseInformation.find_or_create_by!(nomis_offender_id: 'G7658UL') do |info|
  info.tier = 'A'
  info.case_allocation = 'NPS'
  info.manual_entry =  true
  info.local_delivery_unit = ldu1
  info.probation_service = "Wales"
end

CaseInformation.find_or_create_by!(nomis_offender_id: 'G7517GF') do |info|
  info.tier = 'B'
  info.case_allocation = 'NPS'
  info.manual_entry = true
  info.local_delivery_unit = ldu2
  info.probation_service = "Wales"
end

# 3 Test offenders which have handovers in Dec 2020
['G1176UT', 'G0228VG', 'G1289UN'].each do |offender_no|
  CaseInformation.find_or_create_by!(nomis_offender_id: offender_no) do |info|
    info.assign_attributes(tier: 'B',
                           case_allocation:'CRC',
                           probation_service: 'Wales',
                           manual_entry: true,
                           local_delivery_unit: ldu2)
  end
end

# Test offenders which have handovers in Feb 2021
['G2407UH', 'G5884GU'].each do |offender_no|
  CaseInformation.find_or_create_by!(nomis_offender_id: offender_no) do |info|
    info.assign_attributes(tier: 'B',
                           case_allocation:'NPS',
                           probation_service: 'Wales',
                           manual_entry: true,
                           local_delivery_unit: ldu2)
  end
end

# test offender > 18 months before release (20/12/2023)
CaseInformation.find_or_create_by!(nomis_offender_id: 'G7281UH') do |info|
  info.assign_attributes(tier: 'B',
                         case_allocation:'NPS',
                         probation_service: 'Wales',
                         manual_entry: true,
                         local_delivery_unit: ldu2)
end

CaseInformation.find_or_create_by!(nomis_offender_id: 'G3536UF') do |info|
  info.tier = 'A'
  info.case_allocation = 'NPS'
  info.manual_entry = true
  info.local_delivery_unit = ldu2
  info.probation_service = "England"
end

CaseInformation.find_or_create_by!(nomis_offender_id: 'G2260UO') do |info|
  info.tier = 'B'
  info.case_allocation = 'NPS'
  info.manual_entry = true
  info.local_delivery_unit = ldu3
  info.probation_service = "England"
end

