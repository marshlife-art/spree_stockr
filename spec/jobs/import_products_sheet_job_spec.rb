require 'spec_helper'

RSpec.describe ImportProductsSheetJob, type: :job do

  before(:all) do 
    Spree::ShippingCategory.find_or_create_by!(name: 'Default')
  end

  it "should process xlsx files" do
    file_xlsx = "spree_stockr_test_products.xlsx"
    puts "testing file: #{file_xlsx}"
    @sheet = Spree::Sheet.new(name: 'test', header_row: 1)
    @sheet.file.attach(io: File.open("#{RSPEC_ROOT}/fixtures/files/#{file_xlsx}"), filename:file_xlsx)

    @sheet.data["global_map"] = {
      "PCXZRXIB"=>{"key"=>"available_on", "dest"=>"now"},
      # "KBXNPMAP"=>{"key"=>"discontinue_on", "dest"=>"now"},
      "ACXYIBOD"=>{"key"=>"tax_category_id", "dest"=>"1"},
      "QOFLCEWW"=>{"key"=>"shipping_category_id", "dest"=>"1"},
      "NPGQEWUN"=>{"key"=>"promotionable", "dest"=>"true"},
      "STJQPSYL"=>{"key"=>"backorderable", "dest"=>"true"},
      "TKYHQJLD"=>{"key"=>"store_id", "dest"=>"1"},
      "GOAVFBNA"=>{"key"=>"tag_list", "dest"=>"foo,bar,foobar,foobaz"},
      "JOQJHOTP"=>{"key"=>"property", "prop_key"=>"prop0 value", "dest"=>"prop0"},
      "WSIOGADG"=>{"key"=>"property", "prop_key"=>"prop1 value", "dest"=>"prop1"},
      # "ANJXHXHP"=>{"key"=>"taxon_ids", "dest"=>"0, 1"},
      "VVTPXTJC"=>{"key"=>"stock_location_id", "dest"=>"1"}
    }

    @sheet.data["header_map"] = {
      "0"=>{"key"=>"sku"},
      "1"=>{"key"=>"name"},
      "2"=>{"key"=>"description"},
      "3"=>{"key"=>"tag_list"},
      "4"=>{"key"=>"price"},
      "5"=>{"key"=>"cost_price"},
      "6"=>{"key"=>"property", "prop_key"=>"foobar"},
      "7"=>{"key"=>"property", "prop_key"=>"foobaz"},
    }
    
    @sheet.save
    @sheet.reload
    
    expect(GetSheetHeadersJob.perform_now(@sheet.id)).not_to be_nil

    @sheet.reload
    
    expect(ImportProductsSheetJob.perform_now(@sheet.id)).not_to be_nil

    @sheet.reload

    expect(@sheet.file.attached?).to be true

    expect(@sheet.data).not_to be_nil

    expect(@sheet.rows).to be > @sheet.header_row
    
    expect(@sheet.data["history"].last["error"]).to be nil

    expect(@sheet.data["history"].last["success"]).to eq "processed_rows: 3, new_products: 3, missed_rows: 0."

    expect(Spree::Product.where(sheet_id: @sheet.id).count).to be >= @sheet.rows - 1

    products = []
    products << "1234,foo name,foo description,some tag,6.66,3.33,gf,beep".split(',')
    products << "9876,another foo,lorem ipsum foo,some tag,5.55,2.22,,beep".split(',')
    products << "5432,yet another,zomg what is this,a tag,4.44,1.11,zork".split(',')

    products.each do |prod|
      product = Spree::Product.find_by(name: prod[1]) #TODO: use find_by(sku: '...') after sku import is fixed...
      expect(product.sku).to eq(prod[0]) # TODO: fix getting 1234.0 not 1234
      expect(product.description).to eq(prod[2])
      expect(product.tag_list).to include(prod[3]) # TODO: fix getting "some tag foo"
      expect(product.price.to_s).to eq(prod[4])
      expect(product.cost_price.to_s).to eq(prod[5])
      expect(product.property('foobar')).to eq(prod[6]) # TODO: fix getting ""
      expect(product.property('foobaz')).to eq(prod[7]) # TODO: fix getting nil
    end

  end
  
end
