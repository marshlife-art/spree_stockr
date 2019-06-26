class Spree::Sheet < ApplicationRecord

  enum status: [ :active, :processing, :failed_processing, :ready, :done, :failed ]
  has_one_attached :file
  has_many_attached :parsed_json_files

  DEFAULT_PRODUCT_PROP_VALUE = 'none'

  def self.product_props
    [DEFAULT_PRODUCT_PROP_VALUE] + self.global_map_props.keys 
  end

  def self.variant_props
    [ :sku,
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
  end

  def self.header_map_props
    extra_product_props = [:name, :description, :meta_description, :meta_keywords, :meta_title]
    self.product_props + extra_product_props + self.variant_props
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
    GetSheetHeadersJob.perform_later(id)
  end

  def header_map_values
    data["header_map"].keys.collect{|k| data["header_map"][k]["key"] } rescue nil
  end

  def global_map_values
    data["global_map"].collect{|k| k[1] } rescue []
  end

  def sku_index
    header_map_values.find_index "sku" rescue nil
  end

  def map_cells_to_product(cells, product)
    
    hm_values = header_map_values
    return if hm_values.nil?
    gm_values = global_map_values
    
    begin 
      # HEADER MAP
      hm_values.each do |product_prop|
        next if product_prop === DEFAULT_PRODUCT_PROP_VALUE
        cell_index = hm_values.find_index(product_prop) rescue nil
        next if cell_index.nil? or cells[cell_index].nil?
        value = cells[cell_index]
        if self.variant_props.include? product_prop.to_sym
          product.master[product_prop] = value
        else
          product[product_prop] = value
        end
      end
      # GLOBAL MAP
      gm_values.each do |gm|
        next if gm["dest"].nil? or gm["key"].nil?
        gm["dest"] = Time.now if gm["dest"] === 'now'
        if gm["key"] === 'property'
          product.set_property(gm["prop_key"], gm["dest"]) unless gm["prop_key"].nil? or gm["dest"].nil?
        elsif self.variant_props.include? gm["key"].to_sym
          product.master[gm["key"]] = gm["dest"]
        else
          product[gm["key"]] = gm["dest"]
        end
      end

      product.sheet_id = id

      return product
    rescue => err
      return nil
    end
  end

end
  