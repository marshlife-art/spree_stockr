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
      get '/sheets/import_products/:id', to: 'sheets#import_products', as: :import_products_sheet
      get '/sheets/get_parsed_json_files/:id', to: 'sheets#get_parsed_json_files', as: :get_parsed_json_files
      
      get '/sheets/global_map_item/:id', to: 'sheets#global_map_item', as: :sheet_global_map_item
      patch '/sheets/header_map/:id', to: 'sheets#update_header_map', as: :sheet_header_map_patch
      patch '/sheets/global_map/:id', to: 'sheets#update_global_map', as: :sheet_global_map_patch
      get '/sheets/header_map_item/:id', to: 'sheets#header_map_item', as: :sheet_header_map_item

      patch '/sheets/update/:id', to: 'sheets#update', as: :update_sheet
      delete '/sheets/delete/:id', to: 'sheets#delete', as: :delete_sheet
      get '/sheets/status/:id', to: 'sheets#sheet_status', as: :sheet_status
    end
  end
  
end
