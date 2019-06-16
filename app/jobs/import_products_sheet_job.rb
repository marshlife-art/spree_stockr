require 'roo'
require 'json'

class ImportProductsSheetJob < ApplicationJob
  queue_as :default

  def perform(sheet_id)
    sheet = Spree::Sheet.find_by_id sheet_id
    
    # TODO: check for sheet.file && sheet.status
    p "got sheet file: #{sheet.file.inspect}"

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)
    # xlsx_sheet = xlsx.sheet xlsx.sheets[0]

    sheet.data["headers"] = xlsx.row(sheet.header_row)
    p "sheet.data[headers]: #{sheet.data["headers"]}"

    json_data = {rows: []}

    # iterate thru rowz
    xlsx.each_row_streaming(offset: sheet.header_row, max_rows: 10) do |row|
      # Array of Excelx::Cell objects
      json_data[:rows].push row.collect{|c| c.value.to_s.strip}
    end

    sheet.parsed_json_files.attach(io: StringIO.new(json_data.to_json), filename: "file.json", content_type: "application/json")

    p "sheet.parsed_json_files.first.download: #{sheet.parsed_json_files.first.download}"

    sheet.rows = xlsx.last_row

    sheet.save
  end
end
