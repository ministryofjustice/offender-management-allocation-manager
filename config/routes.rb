# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'root#index'

  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  get '/signout', to: 'sessions#destroy' # Legacy signout route
  get '/sign-out', to: 'sessions#destroy' # DPS header signout route
  get '/handovers/email_preferences', to: 'root#handovers_email_preferences'

  resources :prisons, only: [] do
    resources :dashboard, only: :index
    resources :parole_cases, only: :index
    resources :handovers, only: [] do # Yeah I know it effing sucks but legacy code goes brrrrrr
      collection do
        get :upcoming
        get :in_progress
        get :overdue_tasks
        get :com_allocation_overdue
      end
    end
    get 'handovers/:nomis_offender_id/progress_checklist' => 'handover_progress_checklists#edit',
        as: :edit_handover_progress_checklist
    put 'handovers/:nomis_offender_id/progress_checklist' => 'handover_progress_checklists#update',
        as: :update_handover_progress_checklist

    get 'handovers/email_preferences' => 'handovers/email_preferences#edit',
        as: :edit_handover_email_preferences
    put 'handovers/email_preferences' => 'handovers/email_preferences#update',
        as: :update_handover_email_preferences

    resources :staff do
      get 'caseload' => 'caseload#index'
      get 'new_cases' => 'caseload#new_cases'
      get 'caseload/cases' => 'caseload#cases'
      get 'caseload/parole_cases' => 'caseload#parole_cases'
      get 'caseload/updates_required' => 'caseload#updates_required'
      get 'caseload/global' => 'caseload_global#index'
    end

    # POM onboarding
    resources :onboarding, only: [], param: :staff_id do
      member do
        get :position
        post :position
        get :working_pattern
        post :working_pattern
        get :check_answers
        post :check_answers
        get :confirmation
      end

      collection do
        get :search
        post :search
        get :error
      end
    end

    # Bulk reallocation
    resources :reallocations, only: [], param: :nomis_staff_id do
      member do
        get '/' => 'reallocations#index'
        get :check_compare_list, to: 'reallocations#index'
        put :check_compare_list
        get :compare_poms
        get :caseload
        get :error
      end
    end

    resources :prisoners, only: [:show] do
      constraints ->(request) { !PrisonService.womens_prison?(request.path_parameters.fetch(:prison_id)) } do
        get 'new_missing_info' => 'case_information#new'
      end

      constraints ->(request) { PrisonService.womens_prison?(request.path_parameters.fetch(:prison_id)) } do
        get 'new_missing_info' => 'female_missing_infos#new'
        resource :female_missing_info, only: [:show, :update]
      end

      resource :female_missing_info, only: [:new, :show, :update]

      get 'review_case_details'

      collection do
        get 'allocated'
        get 'unallocated'
        get 'missing_information'
        get 'search'
      end

      scope format: true, constraints: { format: 'jpg' } do
        get('image' => 'prisoners#image', as: 'image')
      end

      resources :early_allocations, only: [:new, :index, :show] do
        collection do
          post 'oasys_date'
          post 'eligible'
          post 'discretionary'
          post 'confirm_with_reason'
        end
      end

      # edit action always updates the most recent assessment
      # uses `as: :latest_early_allocation` to avoid clashes with `resources :early_allocations` above
      resource :early_allocation, only: [:edit, :update], as: :latest_early_allocation

      resource :complexity_level, only: [:edit, :update]

      resource :complexity_level_allocation, only: [:edit, :update]

      resources :victim_liaison_officers, only: [:new, :edit, :create, :update, :destroy] do
        member do
          get 'delete'
        end
      end

      resources :parole_reviews, only: [:edit, :update] do
        member do
          get '/enter_parole_hearing_outcome_confirmed', to: 'parole_reviews#edit'
        end
      end

      resources :staff, only: %i[index], controller: 'allocation_staff' do
        resources :build_allocations, only: %i[new show update], controller: 'build_allocations'
      end

      resource :allocation, only: %i[show] do
        member do
          get 'history'
        end
      end

      # Very annoyingly, if SSO needs to re-auth as PUT check_compare_list is
      # executing, it tries to redirect to GET check_compare_list after it's
      # finished, causing a 'no such route' error. So we need this GET version
      # to land the slightly bemused user safely back on the 'Choose a POM' page.
      get 'check_compare_list', to: 'allocation_staff#index'
      put 'check_compare_list', to: 'allocation_staff#check_compare_list'
      get 'compare_poms', to: 'allocation_staff#compare_poms'
    end

    resources :coworking, only: [:new, :create, :destroy], param: :nomis_offender_id, path_names: {
      new: ':nomis_offender_id/new',
    } do
      get('confirm_coworking_removal' => 'coworking#confirm_removal', as: 'confirm_removal')
    end
    get('/coworking/confirm/:nomis_offender_id/:primary_pom_id/:secondary_pom_id' => 'coworking#confirm', as: 'confirm_coworking_allocation')

    resources :case_information, only: %i[new create edit update show], param: :prisoner_id, controller: 'case_information',
                                 path_names: { new: 'new/:prisoner_id' }

    resources :poms, only: %i[index show edit update destroy], param: :nomis_staff_id do
      member do
        get :reallocate
      end
    end

    # routes to show the 2 tabs on PomsController#show
    get 'poms/:nomis_staff_id/tabs/:tab', to: 'poms#show', as: :show_pom_tab

    get '/poms/:nomis_staff_id/non_pom' => 'poms#show_non_pom', as: 'pom_non_pom'

    resources :tasks, only: %i[index]

    resources :responsibilities, only: %i[new create destroy], param: :nomis_offender_id do
      member do
        get :confirm_removal
      end
      collection do
        post('confirm' => 'responsibilities#confirm')
      end
    end

    get('/debugging' => 'debugging#debugging')
    get('/debugging/timeline' => 'debugging#timeline')
    get('prisoners/:id/debugging' => redirect('/prisons/%{prison_id}/debugging?offender_no=%{id}'))
  end

  match '/401', to: 'errors#unauthorized', via: :all
  match '/404', to: 'errors#not_found', via: :all, constraints: ->(req) { req.format == :html }
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/503', to: 'errors#internal_server_error', via: :all

  get '/help/dashboard', to: 'help#dashboard'
  get '/help', to: redirect('/help/dashboard')
  get '/help/missing_cases', to: 'help#missing_cases'
  get '/help/case_responsibility', to: 'help#case_responsibility'

  resources :health, only: %i[index], controller: 'health'
  get '/health/ping', to: 'health#ping'
  resources :status, only: %i[index], controller: 'status'
  resources :info, only: %i[index], controller: 'info'

  namespace :api do
    get('/' => 'api#index')
    resources :offenders, only: [:show], param: :nomis_offender_id
    resources :handovers, only: [:show], controller: :handovers_api
  end

  get '/api/allocation/:offender_no/primary_pom', to: 'api/allocation_api#primary_pom'
  get '/api/allocation/:offender_no', to: 'api/allocation_api#show'
  get '/subject-access-request', to: 'api/sar#show'

  # '/admin' was taken by ActiveAdmin in the past
  namespace :manage do
    resources :audit_events, only: %i[index]

    get 'handover_changes/live', to: 'handover_changes#live'
    get 'handover_changes/historic', to: 'handover_changes#historic'

    get 'deallocate_poms', to: 'deallocate_poms#search'
    patch 'deallocate_poms/confirm', to: 'deallocate_poms#confirm'
    patch 'deallocate_poms', to: 'deallocate_poms#update', as: :deallocate_poms_update
  end

  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get '/swagger-ui.html', to: 'sre_swagger_docs#swagger_ui'
  get '/v3/api-docs', to: 'sre_swagger_docs#open_api_json'

  # Sidekiq admin interface
  constraints ->(request) { SsoIdentity.new(request.session).current_user_is_admin? } do
    require 'sidekiq/web'
    mount Sidekiq::Web => '/sidekiq'
  end
  # Redirect to 'unauthorized' page if user isn't an admin
  get '/sidekiq', to: redirect('/401')

  # catch-all route
  match '*path', to: 'errors#not_found', via: :all, constraints:
    ->(_req) { !Rails.application.config.consider_all_requests_local }
end
