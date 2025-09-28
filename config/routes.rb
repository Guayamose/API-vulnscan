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
end
