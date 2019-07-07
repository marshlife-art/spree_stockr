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
    raise "sheet is already done" if sheet.done? 
    raise "no file" if !sheet.file.attached?
    raise "no mapping data" if sheet.data.blank? 
    raise "no header mapping" if sheet.data["header_map"].blank?
    # p "[ImportProductsSheetJob] got sheet file: #{sheet.file.inspect}"

    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    xlsx = Roo::Spreadsheet.open(sheet.file_path, extension: :xlsx)

    processed_rows = 0
    new_products = 0
    missed_rows = 0

    json_data = []
    header_cell = nil

    taxon_cache = {}

    xlsx.each_row_streaming(offset: sheet.header_row) do |row|
      # Array of Excelx::Cell objects
      cells = row.collect{|c| c.value.to_s.strip rescue ''}

      if cells.all? &:blank?
        p "all cells blank :/"
        missed_rows += 1
        next
      end

      # if only the first cell has a value, consider it a header and taxon, i guess
      # TODO: make this configurable
      if cells[1..-1].all? &:blank?
        header_cell = cells[0]
        p "header_cell: #{header_cell}"
        if taxon_cache[header_cell].nil?
          header_cell_taxon_id = Spree::Taxon.where(name: header_cell.titleize).first_or_create.id
          taxon_cache[header_cell] = header_cell_taxon_id
        else 
          header_cell_taxon_id = taxon_cache[header_cell]
        end
        next
      end

      begin
        
        mapped_product_attributes = sheet.map_cells_to_product(cells, taxon_cache)
        mapped_product_attributes[:taxon_ids] ||= []
        mapped_product_attributes[:taxon_ids] << header_cell_taxon_id
        json_data << mapped_product_attributes
        
        
        new_products += 1
      rescue => err
        p "CAUGHT ERR CREATING PRODUCT! #{err.inspect}"
        # :/
        missed_rows += 1
      end
      processed_rows += 1
    end
    
    # sheet.parsed_json_files.attach(io: StringIO.new(taxon_cache.to_json), filename: "taxon_cache.json", content_type: "application/json")
    # sheet.parsed_json_files.attach(io: StringIO.new(json_data.to_json), filename: "products.json", content_type: "application/json")

    # sheet, data, batch_size, skip_properties, test_batch
    create_products(sheet, json_data, 1000, false, false)
    
    sheet.status = :ready

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) / 60
    p "DONE in #{elapsed} minutes"
    
    write_sheet_history(sheet, {success: "processed_rows: #{processed_rows}, new_products: #{new_products}, missed_rows: #{missed_rows}. took #{elapsed} minutes."})
    sheet.save

  end

  def create_products(sheet, product_data, batch_size=100, skip_properties=false, test_batch=false)
    total_batches = product_data.count / batch_size
    batches_done = 0
    product_data.each_slice(batch_size) do |s|
      s.each do |mapped_product_attributes|
        variant = Spree::Variant.where(sku: mapped_product_attributes[:sku])
        new_product = variant.first.product unless variant.empty?
        new_product ||= Spree::Product.create

        new_product.update mapped_product_attributes.except(:master, :properties)
        
        unless skip_properties
          properties = mapped_product_attributes[:properties]
          properties.each do |prop|
            new_product.set_property(prop[0], prop[1])
          end
        end

        master_attributes = mapped_product_attributes[:master]
        new_product.master.update master_attributes unless master_attributes.blank?
      end
      batches_done += 1
      sheet.data["progress"] = '%.2f' % (batches_done.to_f/total_batches)
      sheet.save
      p "[ImportProductsSheetJob] #{s.count} products. #{sheet.data["progress"]}"
      break if test_batch
    end
  end

  def write_sheet_history(sheet, opts) 
    sheet.data["history"] ||= []
    sheet.data["history"] << {date: Time.now, success: opts[:success], error: opts[:error]}
  end

end
