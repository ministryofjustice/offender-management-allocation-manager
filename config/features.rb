Flipflop.configure do
  strategy :active_record
  strategy :default

  feature :auto_delius_import,
          default: false,
          description: 'Load case information via nDelius, disable manual editing'
  feature :early_allocation,
          default: false,
          description: 'Early Allocation to probation team'
end
