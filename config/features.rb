Flipflop.configure do
  strategy :active_record
  strategy :default

  feature :link_allocation_info,
          default: false,
          description: 'Link allocation info page from allocated offenders tab'
  feature :prisoner_profile,
          default: false,
          description: 'Show the prisoner profile from caseload pages'
end
