require 'roo'
require 'json'

class ImportProductsSheetJob < ApplicationJob
  queue_as :default

  def perform(sheet_id)
    begin
      sheet = Spree::Sheet.find_by_id sheet_id
      process_sheet(sheet)
    rescue => error
      puts "[ImportProductsSheetJob] CAUGHT ERR: #{error}"
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
      cells = row.collect{|c| c.value.to_s.strip}
      begin
        new_product = Spree::Product
        .where(sku: cells[sku_index])
        .first_or_create! do |product|
          sheet.map_cells_to_product(cells, product)
        end
        new_product.save
        new_products += 1
      rescue
        # :/
        missed_rows += 1
      end
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
