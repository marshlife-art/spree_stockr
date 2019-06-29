require 'roo'
require 'json'

class ParseProductsSheetJob < ApplicationJob
  queue_as :default

  def perform(sheet_id)
    
    begin
      sheet = Spree::Sheet.find_by_id sheet_id
      process_sheet(sheet)
    rescue => error
      puts "[ParseProductsSheetJob] CAUGHT error: #{error}"
      if sheet
        sheet.status = :failed_processing
        write_sheet_history(sheet, {error: error})
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
  
    # p "[ParseProductsSheetJob] got sheet file: #{sheet.file.inspect}"

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)

    sheet.data["headers"] = xlsx.row(sheet.header_row)

    sheet.rows = xlsx.last_row

    sheet.parsed_json_files.each {|json_file| json_file.purge}
    
    processed_rows = 0

    if sheet.group_column != nil 
      json_data = {}

      xlsx.each_row_streaming(offset: sheet.header_row) do |row|
        group_col = row[sheet.group_column].value.to_s.strip rescue ''
        json_data[group_col] ||= []
        json_data[group_col].push row.collect{|c| c.value.to_s.strip}
      end

      json_data.keys.each do |key|
        sheet.parsed_json_files.attach(io: StringIO.new(json_data[key].to_json), filename: "#{key}_rows.json", content_type: "application/json")
        sheet.data["parsed_json_files"] ||= {}
        sheet.data["parsed_json_files"][key] = json_data[key].count
      end

    else
      while(processed_rows < sheet.rows) do
        # p "while processed_rows(#{processed_rows}) < sheet.rows(#{sheet.rows})"
        json_data = {rows: []}

        # iterate thru rowz
        offset = processed_rows == 0 ? (sheet.header_row > sheet.rows ? sheet.rows : sheet.header_row ) : processed_rows

        break if offset >= sheet.rows
        
        xlsx.each_row_streaming(offset: offset, max_rows: 10000) do |row|
          json_data[:rows].push row.collect{|c| c.value.to_s.strip}
          processed_rows += 1
        end

        sheet.parsed_json_files.attach(io: StringIO.new(json_data.to_json), filename: "rows.json", content_type: "application/json")

      end
    end

    sheet.status = :ready
    write_sheet_history(sheet, {success: "parsed rows: #{processed_rows}"})
    sheet.save

  end

  def write_sheet_history(sheet, opts) 
    sheet.data["history"] ||= []
    sheet.data["history"] << {date: Time.now, success: opts[:success], error: opts[:error]}
  end
end
