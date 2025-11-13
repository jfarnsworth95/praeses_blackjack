Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get "/settings", to: "settings#index"
  resources :settings

  get "/game", to: "game_sessions#start_game"
  get "/bet", to: "game_sessions#betting_phase"
  post "/submit_bet", to: "game_sessions#submit_bet", as: :submit_bet
  get "/insurance", to: "game_sessions#insurance_phase"
  post "game_sessions/insurance_response", to: "game_sessions#insurance_response"
  get "/play", to: "game_sessions#play_phase"
  post "game_sessions/play", to: "game_sessions#play"
  get "/resolve", to: "game_sessions#resolve_phase"
  post "game_sessions/next_round", to: "game_sessions#next_round"
  get "/game_over", to: "game_sessions#all_pc_bankrupt_phase"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  get "/", to: "main_menu#index"
  root "main_menu#index"

end
