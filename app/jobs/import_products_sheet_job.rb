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
    
    p "[ImportProductsSheetJob] got sheet file: #{sheet.file.inspect}"

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)

    processed_rows = 0

    xlsx.each_row_streaming(offset: sheet.header_row) do |row|
      # Array of Excelx::Cell objects
      row.collect{|c| c.value.to_s.strip}

      processed_rows += 1
    end

    
 

    sheet.status = :ready
    write_sheet_history(sheet, {success: "imported products"})
    sheet.save

  end

  def write_sheet_history(sheet, opts) 
    sheet.data["history"] ||= []
    sheet.data["history"] << {date: Time.now, success: opts[:success], error: opts[:error]}
  end

end
