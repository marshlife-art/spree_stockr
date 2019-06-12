class Spree::Sheet < ApplicationRecord

  has_one_attached :file

  def file_path
    # Rails.application.routes.url_helpers.rails_blob_path(sheet.file, only_path: true)
    ActiveStorage::Blob.service.path_for(file.key)
  end

end
  