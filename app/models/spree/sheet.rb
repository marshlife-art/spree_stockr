class Spree::Sheet < ApplicationRecord

  enum status: [ :active, :processing, :failed_processing, :ready, :done, :failed ]
  has_one_attached :file
  has_many_attached :parsed_json_files

  DEFAULT_PRODUCT_PROP_VALUE = 'none'

  def self.product_props
    [DEFAULT_PRODUCT_PROP_VALUE] + [:sku, :cost_currency, :cost_price, :price, :taxons] + self.global_map_props.keys 
  end

  def self.variant_props
    [ :weight,
      :height,
      :width,
      :depth,
      :position,
      :track_inventory
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
      # TODO: date parsing...
      # discontinue_on: { 
      #   require_choice: false,
      #   multiple: false,
      #   data: [{id: 'now', text: 'Time.now()'}]
      # },
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
      taxon_ids: { 
        require_choice: false,
        multiple: true,
        data: Spree::Taxon.all.limit(250).map{|i| {id: i.id, text: i.name}}
      }
      # TODO: better stock handling...
      # stock_location_id: { 
      #   require_choice: true,
      #   multiple: false,
      #   data: Spree::StockLocation.all.map{|i| {id: i.id, text: i.name}}
      # }
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
    data["header_map"].keys.collect{|k| data["header_map"][k] } rescue nil
  end

  def global_map_values
    data["global_map"].collect{|k| k[1] } rescue []
  end

  def map_cells_to_product(cells, taxon_cache={})
    product_attributes = {}
    product_attributes[:master] = {}
    product_attributes[:properties] = []

    hm_values = header_map_values
    return if hm_values.nil?
    
    # begin 
      # HEADER MAP
      hm_values.each do |hm|
        product_prop = hm["dest"]
        next if product_prop == DEFAULT_PRODUCT_PROP_VALUE
        # cell_index = hm_values.find_index{|v| v["key"] == product_prop} rescue nil
        # next if cell_index.nil? or cells[cell_index].nil?
        value = hm["keys"].split(",").map(&:to_i).collect{|i| cells[i].titleize}.join(' ') rescue ''

        unless hm["price_multiplier"].nil? or hm["price_multiplier"].to_f == 0 or value.to_f.to_s != value
          value = '%.2f' % (value.to_f * hm["price_multiplier"].to_f + value.to_f)
        end

        if product_prop == 'property'
          product_attributes[:properties] << [hm["prop_key"], value] unless hm["prop_key"].blank? or value.blank?
        elsif Spree::Product.has_attribute? product_prop or Spree::Product.method_defined? product_prop
          if product_prop == 'taxon_ids'
            product_attributes[:taxon_ids] ||= []
            product_attributes[:taxon_ids] += value.split(',').map(&:to_i)
          elsif product_prop == 'taxons'
            product_attributes[:taxon_ids] ||= []
            product_attributes[:taxon_ids] += value.split(',').collect do |v|
              v = v.strip
              if taxon_cache[v.strip].nil?
                taxon_id = Spree::Taxonomy.where("lower(name) = ?", v.downcase).first.try(:taxons).try(:first).try(:id)
                taxon_id ||= Spree::Taxonomy.where(name: v.titleize).first_or_create.try(:taxons).try(:first).try(:id)
                taxon_cache[v.strip] = taxon_id unless taxon_id.nil?
              end
              taxon_cache[v]
            end
          else
            product_attributes[product_prop.to_sym] ||= ""
            product_attributes[product_prop.to_sym] << " #{value.to_s}"
            product_attributes[product_prop.to_sym].strip!
          end
        elsif Spree::Variant.has_attribute? product_prop or Spree::Variant.method_defined? product_prop
          product_attributes[:master][product_prop.to_sym] ||= ""
          product_attributes[:master][product_prop.to_sym] << " #{value.to_s}"
          product_attributes[:master][product_prop.to_sym].stirp!
        else 
          p "[Sheet] dunno about this header :/ #{product_prop}"
        end
      end
      # GLOBAL MAP
      gm_values = global_map_values
      gm_values.each do |gm|
        next if gm["dest"].nil? or gm["key"].nil?
        gm["dest"] = Time.now if gm["dest"] == 'now'
        if gm["key"] == 'property'
          product_attributes[:properties] << [gm["prop_key"], gm["dest"]] unless gm["prop_key"].nil? or gm["dest"].nil?
        elsif Spree::Product.has_attribute? gm["key"] or Spree::Product.method_defined? gm["key"]
          if gm["key"] == 'taxon_ids'
            product_attributes[gm["key"].to_sym] ||= []
            product_attributes[gm["key"].to_sym] += gm["dest"].split(',').map(&:to_i)
          else
            product_attributes[gm["key"].to_sym] ||= ""
            product_attributes[gm["key"].to_sym] << " #{gm["dest"].to_s}"
            product_attributes[gm["key"].to_sym].strip!
          end
        elsif Spree::Variant.has_attribute? gm["key"] or Spree::Variant.method_defined? gm["key"]
          product_attributes[:master][gm["key"].to_sym] ||= ""
          product_attributes[:master][gm["key"].to_sym] << " #{gm["dest"]}"
          product_attributes[:master][gm["key"].to_sym].strip!
        else 
          p "[Sheet] dunno about this global map ref :/  #{gm["key"]}"
        end
      end

      product_attributes[:sheet_id] = id

      return product_attributes
    # rescue => err
    #   return product_attributes
    # end
  end

end
  