require 'roo'

class GetSheetHeadersJob < ApplicationJob
  queue_as :default

  def perform(sheet_id)
    sheet = Spree::Sheet.find_by_id sheet_id

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)
    # xlsx_sheet = xlsx.sheet xlsx.sheets[0]

    sheet.data["headers"] = xlsx.row(sheet.header_row)
    # p "sheet.data[headers]: #{sheet.data["headers"]}"

    sheet.save

  end
end
