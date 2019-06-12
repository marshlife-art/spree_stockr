require 'csv'

namespace :marsh do
  desc "load products from .csv into database"
  task :load_products_csv, [:file] => [:environment] do |t, args|
    puts "reading: #{args.file}..."
    products = CSV.read(args.file, headers: true)

    puts "read #{products.count} products."

    header_map = {
      
    }
    (1..20).each do 
      idx = rand(0..products.count)
      product = products.by_row[idx]


    end

    # HEADERZ
    # ["UNF", "UPC Code", "Brand", "Long Name", "Description", "Advertising Description", "PK", "Size", "Unit Type", "M", "W/S Price", "U Price", "SRP", "CHE", "YRK", "DAY", "ATL", "IOW", "GRW", "PHL", "SNW", "SAR", "RAC", "HVA", "TWC", "HOW", "RCH", nil, "#", "Category Description", "a", "r", "c", "l", "d", "f", "g", "v", "w", "y", "k", "ft", "mm", "og", "s", "n"] 

    

  end

  desc "load products from .xlsx"
  task :load_products_xlsx, [:file] => [:environment] do |t, args|
    
    xlsx = Roo::Spreadsheet.open(args.file)

    sheet = xlsx.sheet xlsx.sheets[0]
    headers = sheet.row(6)

     # Will yield 4 rows (it's automatically incremented by 1) after the supplied offset.
    xlsx.each_row_streaming(max_rows: 3) do |row|
      puts row.inspect # Array of Excelx::Cell objects
    end


  end


end
