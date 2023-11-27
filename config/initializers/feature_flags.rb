# Feature Flags - super simple, they are just constants - it works
# USE_FEATURE = ENV.fetch('USE_FEATURE', '').strip == '1'

ENABLE_EVENT_BASED_PROBATION_CHANGE = ENV.fetch('ENABLE_EVENT_BASED_PROBATION_CHANGE', '').strip == '1'
