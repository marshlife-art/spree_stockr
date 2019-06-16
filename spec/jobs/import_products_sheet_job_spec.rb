require 'spec_helper'
# include ActionDispatch::TestProcess::FixtureFile

RSpec.describe ImportProductsSheetJob, type: :job do
  
  Dir.glob("#{RSPEC_ROOT}/fixtures/files/**/*.xlsx") do |file_xlsx|
  
    it "should process xlsx files" do
      puts "testing file: #{file_xlsx}"
      @sheet = Spree::Sheet.new(name: 'test', header_row: 6)
      @sheet.file.attach(io: File.open(file_xlsx), filename:file_xlsx)
      @sheet.save
      @sheet.reload
      
      expect(ImportProductsSheetJob.perform_now(@sheet.id)).not_to be_nil

      @sheet.reload

      expect(@sheet.file.attached?).to be true

      expect(@sheet.data).not_to be_nil

      expect(@sheet.parsed_json_files.attached?).to be(true)

      expect(@sheet.rows).to be > @sheet.header_row
    end

  end
    
  
  
  # before(:all) do
  #   @sheet = Spree::Sheet.new(name: 'test', header_row: 6)
  #   @sheet.file.attach(io: File.open("#{RSPEC_ROOT}/fixtures/files/sheet_test.xlsx"), filename: 'sheet_test.xlsx')
  #   @sheet.save
  # end

  # it "should process xlsx files" do
  #   expect(ImportProductsSheetJob.perform_now(@sheet.id)).not_to be_nil

  #   @sheet.reload

  #   expect(@sheet.file.attached?).to be true

  #   expect(@sheet.data).not_to be_nil

  #   expect(@sheet.parsed_json_files.attached?).to be(true)

  #   expect(@sheet.rows).to be > @sheet.header_row
  # end
  
end
