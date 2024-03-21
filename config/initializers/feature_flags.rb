# Feature Flags - super simple, they are just constants - it works
# USE_FEATURE = ENV.fetch('USE_FEATURE', '').strip == '1'

USE_PPUD_PAROLE_DATA = ENV.fetch('USE_PPUD_PAROLE_DATA', '').strip == '1'
