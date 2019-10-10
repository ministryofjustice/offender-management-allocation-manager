Rswag::Api.configure do |c|
  c.swagger_root = Rails.root.to_s + '/public'
  c.swagger_filter = ->(swagger, env) { swagger['host'] = env['HTTP_HOST'] }
end
