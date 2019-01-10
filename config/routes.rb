Rails.application.routes.draw do
  root to: 'dashboard#index'

  get '/status', to: 'status#index'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'

  get('health' => 'health#index')

  get('/allocations' => 'allocations#index')
  get('/allocations/allocated' => 'allocations#allocated')
  get('/allocations/awaiting' => 'allocations#awaiting')
  get('/allocations/missing-information' => 'allocations#missing_information')

  get('/poms' => 'poms#index')
  get('/poms/:id' => 'poms#show', as: 'poms_show')
  get('/poms/:id/edit' => 'poms#edit', as: 'poms_edit')

  get('/prisoners/:id' => 'prisoners#show', as: 'prisoners_show')

  get('/allocate_prison_offender_managers/:noms_id' => 'allocate_prison_offender_managers#show',
      as: 'allocate_prison_offender_managers_show')
  get('/allocate_prison_offender_managers/:noms_id/edit' => 'allocate_prison_offender_managers#edit',
      as: 'allocate_prison_offender_managers_edit')
end
