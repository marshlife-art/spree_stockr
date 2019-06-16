## product map notes

map for per-product-row as well as all products/rows (e.g. store_id will apply to all stores)

```ruby
2.5.1 :032 > pp product.attributes
{
 "name"=>"Ruby on Rails Tote",
 "description"=>
  "Dolores voluptas sit voluptas quod et repudiandae sunt accusamus. Voluptatem distinctio est cupiditate perspiciatis sed. Ratione ut sint cumque dignissimos magni eos veniam. Beatae sit non nulla aperiam. Repellendus suscipit sint cupiditate libero.",
 "available_on"=>Sun, 02 Jun 2019 19:36:39 UTC +00:00,
 "meta_description"=>nil,
 "meta_keywords"=>nil,
 "tax_category_id"=>1,        > dropdown of all tax categories 
 "shipping_category_id"=>1,   > dropdown of all shipping categories 
 "promotionable"=>true,
 "meta_title"=>nil,
 "discontinue_on"=>nil,
 "store_id"=>1,               > dropdown of all stores
 "tag_list"=>nil
}
2.5.1 :033 > pp product.master
#<Spree::Variant:0x00007fee7a8029b8
{
 sku: "ROR-00011",
 weight: 0.0,
 height: nil,
 width: nil,
 depth: nil,
 cost_price: 0.17e2,
 position: 1,
 cost_currency: "USD",
 track_inventory: true,
 tax_category_id: nil,
 discontinue_on: nil
 price: 12.99 
 }

 product.set_property("some name", "some value")

 ...tags 
 
 ...taxonz 


Spree::StockItem  && backorderable
  stock_location_id: The ID for the Spree::StockLocation where the stock item is located.
  variant_id: The ID for the Spree::Variant that this stock item represents.
  count_on_hand: The number of units currently in inventory. See Count on hand  for more information.
  backorderable: Sets whether the stock item should be backorderable.



# handle csv
require 'csv'
products = CSV.read(args.file, headers: true)

puts "read #{products.count} products."

header_map = {
  
}
(1..20).each do 
  idx = rand(0..products.count)
  product = products.by_row[idx]


end

```
