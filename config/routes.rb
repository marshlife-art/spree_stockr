Spree::Core::Engine.add_routes do
  # Add your extension routes here

  Spree::Core::Engine.add_routes do
    namespace :admin, path: Spree.admin_path do
      # resources :sheets
      get '/sheets', to: 'sheets#index'
      get '/sheets/new', to: 'sheets#new', as: :new_sheet
      post '/sheets/new', to: 'sheets#create', as: :create_new_sheet
      get '/sheets/edit/:id', to: 'sheets#edit', as: :edit_sheet
      get '/sheets/process/:id', to: 'sheets#process_file', as: :process_sheet
      get '/sheets/get_parsed_json_files/:id', to: 'sheets#get_parsed_json_files', as: :get_parsed_json_files
      get '/sheets/header_map/:id', to: 'sheets#header_map', as: :sheet_header_map
      get '/sheets/global_map/:id', to: 'sheets#global_map', as: :sheet_global_map
      patch '/sheets/update/:id', to: 'sheets#update', as: :update_sheet
      delete '/sheets/delete/:id', to: 'sheets#delete', as: :delete_sheet
    end
  end
  
end
