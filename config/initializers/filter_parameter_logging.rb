# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [:password,
                                               :code,
                                               :message,
                                               :more_detail,
                                               :suitability_detail,
                                               :override_detail,
                                               :reason,
                                               :reason_text,
                                               :system_admin_note]
