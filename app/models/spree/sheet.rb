class Spree::Sheet < ApplicationRecord

  enum status: [ :active, :processing, :failed_processing, :ready, :done, :failed ]
  has_one_attached :file
  has_many_attached :parsed_json_files

  def self.product_props
    [ :available_on,
      :tax_category_id,
      :shipping_category_id,
      :promotionable,
      :discontinue_on,
      :store_id,
      :tag_list,
      :discontinue_on,
      :property,
      :taxons,
      :stock_location_id,
      :backorderable
    ]
  end
  
  def self.global_map_props
    self.product_props
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
end
  