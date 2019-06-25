require 'roo'

class GetSheetHeadersJob < ApplicationJob
  queue_as :default

  def perform(sheet_id)
    begin
      sheet = Spree::Sheet.find_by_id sheet_id
      process_sheet(sheet)
    rescue => error
      if sheet 
        write_sheet_history(sheet, {error: error})
        sheet.status = :failed_processing
        sheet.save
      end
      raise
    end
  end

  private 
  def process_sheet(sheet)
    raise "sheet not found" if !sheet 
    raise "sheet is currently processing" if sheet.processing? 
    raise "no file" if !sheet.file.attached?

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)
    sheet.data["headers"] = xlsx.row(sheet.header_row)
    sheet.rows = xlsx.last_row
    write_sheet_history(sheet, {success: "processed header rows"})
    sheet.save
  end

  def write_sheet_history(sheet, opts) 
    sheet.data["history"] ||= []
    sheet.data["history"] << {date: Time.now, success: opts[:success], error: opts[:error]}
  end
  
end
