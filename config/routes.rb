Rails.application.routes.draw do
  root to: 'dashboard#index'

  get '/status', to: 'status#index'
  get '/auth/:provider/callback', to: 'sessions#create'

  get('health' => 'health#index')

  get('/allocations' => 'allocations#index')
end
