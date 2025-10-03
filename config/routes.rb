Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      namespace :auth do
        post :password_login, to: 'password#login'
        post :refresh,        to: 'tokens#refresh'
        post :revoke,         to: 'tokens#revoke'
        get  :whoami,         to: 'tokens#whoami'
      end
      resources :scans,    only: %i[create show index]
      resources :findings, only: %i[create index]
    end
  end

  # === Admin HTML UI (read-only) ===
  namespace :admin do
    root to: 'dashboard#index'
    resources :organizations, only: %i[index show]
    resources :users,         only: %i[index show]
    resources :scans,         only: %i[index show]
    resources :findings,      only: %i[index show]
  end

  # opcional: redirigir la raíz del sitio al panel
  root to: redirect('/admin')
end
