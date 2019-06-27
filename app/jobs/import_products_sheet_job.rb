require 'roo'
require 'json'

class ImportProductsSheetJob < ApplicationJob
  queue_as :default

  def perform(sheet_id)
    begin
      sheet = Spree::Sheet.find_by_id sheet_id
      process_sheet(sheet)
    rescue => error
      puts "[ImportProductsSheetJob] CAUGHT ERR: #{error.inspect}"
      sheet.status = :failed_processing
      sheet.data["history"] ||= []
      sheet.data["history"] << {date: Time.now, error: error}
      sheet.save
      raise
    end
  end

  private
  def process_sheet(sheet)
    raise "sheet not found" if !sheet 
    raise "sheet is currently processing" if sheet.processing? 
    raise "no file" if !sheet.file.attached?
    raise "no mapping data" if sheet.data.blank? 
    raise "no header mapping" if sheet.data["header_map"].blank?
    sku_index = sheet.sku_index
    raise "no sku index" if sku_index.nil?

    # p "[ImportProductsSheetJob] got sheet file: #{sheet.file.inspect}"

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)

    processed_rows = 0
    new_products = 0
    missed_rows = 0

    xlsx.each_row_streaming(offset: sheet.header_row) do |row|
      # Array of Excelx::Cell objects
      cells = row.collect{|c| c.value.to_s.strip rescue ''}
      # begin
        variant = Spree::Variant.where(sku: cells[sku_index])
        new_product = variant.first.product unless variant.empty?

        new_product ||= Spree::Product.create
        
        mapped_product_attributes = sheet.map_cells_to_product(cells)
        p "mapped_product_attributes: #{mapped_product_attributes}"
        
        master_attributes = mapped_product_attributes[:master]
        properties = mapped_product_attributes[:properties]
        p "master_attributes: #{master_attributes}"
        p '# # # # # #'
        p "properties: #{properties}"
        p '# # # # # #'
        p "attributes: #{mapped_product_attributes.except(:master, :properties)}"
        p '# # # # # #'

        new_product.update mapped_product_attributes.except(:master, :properties)
        properties.each do |prop|
          new_product.set_property(prop[0], prop[1])
        end
        new_product.master.update master_attributes
        new_product.save!
        p "!!!!w00t!!!! CREATED NEW_PRODUCT #{new_product.inspect}"
        new_products += 1
      # rescue => err
      #   p "CAUGHT ERR CREATING PRODUCT! #{err.inspect}"
      #   # :/
      #   missed_rows += 1
      # end
      processed_rows += 1
    end

    sheet.status = :ready
    write_sheet_history(sheet, {success: "processed_rows: #{processed_rows}, new_products: #{new_products}, missed_rows: #{missed_rows}."})
    sheet.save

  end

  def write_sheet_history(sheet, opts) 
    sheet.data["history"] ||= []
    sheet.data["history"] << {date: Time.now, success: opts[:success], error: opts[:error]}
  end

end
