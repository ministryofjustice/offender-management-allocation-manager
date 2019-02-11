Rails.application.routes.draw do
  root to: 'dashboard#index'

  get '/status', to: 'status#index'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout', to: 'sessions#destroy'

  get('health' => 'health#index')

  get('/allocations' => 'allocations#index')

  get('/poms' => 'poms#index')
  get('/poms/:id' => 'poms#show', as: 'poms_show')
  get('/poms/:id/edit' => 'poms#edit', as: 'poms_edit')

  get('/prisoners/:id' => 'prisoners#show', as: 'prisoners_show')

  get('/allocate/:nomis_offender_id' => 'allocates#show',
      as: 'allocates_show')
  get('/allocate/confirm/:nomis_offender_id/:nomis_staff_id' => 'allocates#new',
      as: 'new_allocates')
  resource :allocates, only: %i[ create ]

  get('/overrides/new/:nomis_offender_id/:nomis_staff_id' => 'overrides#new',
      as: 'new_overrides')

  resource :overrides,  only: %i[create]

end
