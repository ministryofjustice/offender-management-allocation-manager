Rswag::Api.configure do |c| # rubocop:disable Naming/FileName
  c.openapi_root = "#{Rails.root}/public"
  c.swagger_filter = ->(swagger, env) { swagger['host'] = env['HTTP_HOST'] }
end
