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
    # p "sheet.data[headers]: #{sheet.data["headers"]}"

    sheet.rows = xlsx.last_row
    processed_rows = 0

    while(processed_rows < sheet.rows) do
      p "while processed_rows(#{processed_rows}) < sheet.rows(#{sheet.rows})"
      json_data = {rows: []}

      # iterate thru rowz
      offset = processed_rows == 0 ? sheet.header_row : processed_rows

      xlsx.each_row_streaming(offset: offset, max_rows: 10000) do |row|
        # Array of Excelx::Cell objects
        json_data[:rows].push row.collect{|c| c.value.to_s.strip}
        processed_rows += 1
      end

      sheet.parsed_json_files.attach(io: StringIO.new(json_data.to_json), filename: "rows.json", content_type: "application/json")

      # p "sheet.parsed_json_files.last.download: #{sheet.parsed_json_files.last.download}"


    end

    sheet.status = :ready
    sheet.save

  end
end
