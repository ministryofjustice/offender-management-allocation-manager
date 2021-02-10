Flipflop.configure do
  strategy :active_record
  strategy :default

  feature :auto_delius_import,
          default: false,
          description: 'Load case information via nDelius, disable manual editing'
  feature :early_allocation,
          default: true,
          description: 'Early Allocation to probation team'
  feature :womens_estate,
          default: false,
          description: 'Womens Estate with mandatory complexity level'
end
