require 'spec_helper'

RSpec.describe ParseProductsSheetJob, type: :job do

  it "should fail and write history if sheet is currently processing" do 
    @sheet = Spree::Sheet.new(name: 'test', header_row: 1)
    @sheet.save
    @sheet.processing!
    @sheet.reload
    
    expect { ParseProductsSheetJob.perform_now(@sheet.id) }.to raise_error(RuntimeError, "sheet is currently processing")

    @sheet.reload

    expect(@sheet.data).not_to be_nil

    expect(@sheet.data["history"].last["error"]).to be_truthy, "expected last history item to have an error, got: #{@sheet.data["history"].last}"

  end

  Dir.glob("#{RSPEC_ROOT}/fixtures/files/**/*.xlsx") do |file_xlsx|
  
    it "should process xlsx files" do
      puts "testing file: #{file_xlsx}"
      @sheet = Spree::Sheet.new(name: 'test', header_row: 6)
      @sheet.file.attach(io: File.open(file_xlsx), filename:file_xlsx)
      @sheet.save
      @sheet.reload
      
      expect(ParseProductsSheetJob.perform_now(@sheet.id)).not_to be_nil

      @sheet.reload

      expect(@sheet.file.attached?).to be true

      expect(@sheet.data).not_to be_nil

      expect(@sheet.parsed_json_files.attached?).to be(true)

      expect(@sheet.rows).to be > @sheet.header_row

      expect(@sheet.data["history"].last["error"]).to be nil

    end

  end
  
end
