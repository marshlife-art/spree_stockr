class Spree::Sheet < ApplicationRecord

  enum status: [ :active, :processing, :failed_processing, :ready, :done, :failed ]
  has_one_attached :file
  has_many_attached :parsed_json_files

  def self.product_props
    ['Select Product Attribute'] + self.global_map_props.keys 
  end

  def self.header_map_props
    extra_product_props = [:name, :description, :meta_description, :meta_keywords, :meta_title]
    variant_props = [
      :sku,
      :weight,
      :height,
      :width,
      :depth,
      :position,
      :cost_currency,
      :track_inventory,
      :cost_price,
      :price
    ]
    self.product_props + extra_product_props + variant_props
  end

  def self.global_map_props
    {
      available_on: { 
        require_choice: false,
        multiple: false,
        data: [{id: 'now', text: 'Time.now()'}]
      },
      discontinue_on: { 
        require_choice: false,
        multiple: false,
        data: [{id: 'now', text: 'Time.now()'}]
      },
      tax_category_id: { 
        require_choice: true,
        multiple: false,
        data: Spree::TaxCategory.order(:name).map{|i| {id: i.id, text: i.name}}
      },
      shipping_category_id: { 
        require_choice: true,
        multiple: false,
        data: Spree::ShippingCategory.all.map{|i| {id: i.id, text: i.name}}
      },
      promotionable: { 
        require_choice: true,
        multiple: false,
        data: [{id: 'true', text: 'true'}, {id: 'false', text: 'false'}]
      },
      backorderable: { 
        require_choice: true,
        multiple: false,
        data: [{id: 'true', text: 'true'}, {id: 'false', text: 'false'}]
      },
      store_id: { 
        require_choice: true,
        multiple: false,
        data: Spree::Store.all.map{|store| {id: store.id, text: store.name}}
      },
      tag_list: { 
        require_choice: false,
        multiple: true,
        data: Spree::Tag.all.limit(250).map{|store| {id: store.id, text: store.name}}
      },
      property: { 
        require_choice: false,
        multiple: false,
        data: []
      },
      taxons: { 
        require_choice: false,
        multiple: true,
        data: Spree::Taxon.all.limit(250).map{|i| {id: i.id, text: i.name}}
      },
      stock_location_id: { 
        require_choice: true,
        multiple: false,
        data: Spree::StockLocation.all.map{|i| {id: i.id, text: i.name}}
      }
    }
  end

  def file_path
    # Rails.application.routes.url_helpers.rails_blob_path(sheet.file, only_path: true)
    ActiveStorage::Blob.service.path_for(file.key)
  end

  def status_class
    case status_before_type_cast
    when Spree::Sheet.statuses[:active]
      'label-primary'
    when Spree::Sheet.statuses[:processing]
      'label-info'
    when Spree::Sheet.statuses[:failed_processing]
      'label-warning'
    when Spree::Sheet.statuses[:ready]
      'label-success'
    when Spree::Sheet.statuses[:done]
      'label-default'
    when Spree::Sheet.statuses[:failed]
      'label-danger'
    end
  end

  def update_header_row
    GetSheetHeadersJob.perform_now(id)
  end

end
  