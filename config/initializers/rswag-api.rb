# rubocop:disable Naming/FileName
Rswag::Api.configure do |c|
  # rubocop:enable Naming/FileName
  c.swagger_root = "#{Rails.root}/public"
  c.swagger_filter = ->(swagger, env) { swagger['host'] = env['HTTP_HOST'] }
end
