Flipflop.configure do
  strategy :active_record
  strategy :default

  feature :link_allocation_info,
          default: true,
          description: 'Link allocation info page from allocated offenders tab'
  feature :prisoner_profile,
          default: true,
          description: 'Show the prisoner profile from caseload pages'
  feature :show_handover_dates,
          default: false,
          description: 'Show offender handover dates on prisoner profile'
  feature :auto_delius_import,
          default: false,
          description: 'Load case information via nDelius, disable manual editing'
end
