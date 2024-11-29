require 'sidekiq/web'
# require 'sidekiq/cron/web'

Rails.application.routes.draw do
  devise_for :users, sign_out_via: [:get, :delete]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"
  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    mount Sidekiq::Web => '/sidekiq'
  end

  root 'home#index'

  resources :loans do
    member do
      get :edit_readjustment
      patch :update_readjustment
      patch :approve
      patch :reject
      patch :accept
      patch :adjust
      patch :request_readjustment
      patch :repay
    end
  end

  namespace :admin do
    resources :loans, only: [:index, :show, :update, :edit] do
      member do
        get :edit_readjustment
        patch :accept_readjustment
        patch :reject_readjustment
        patch :update_readjustment
        patch :approve
        patch :reject
        # patch :adjust
      end
    end
    resources :users, only: [:index, :show]
  end

  resources :wallets, only: [:show]
end
