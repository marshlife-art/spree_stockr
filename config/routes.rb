Spree::Core::Engine.add_routes do
  # Add your extension routes here

  Spree::Core::Engine.add_routes do
    namespace :admin, path: Spree.admin_path do
      # resources :sheets
      get '/sheets', to: 'sheets#index'
      get '/sheets/new', to: 'sheets#new', as: :new_sheet
      post '/sheets/new', to: 'sheets#create', as: :create_new_sheet
      get '/sheets/edit/:id', to: 'sheets#edit', as: :edit_sheet
    end
  end
  
end
