Rails.application.routes.draw do
  root to: 'status#index'

  get '/auth/:provider/callback', to: 'sessions#create'

  get('health' => 'health#index')

  get('/allocations' => 'allocations#index')
end
