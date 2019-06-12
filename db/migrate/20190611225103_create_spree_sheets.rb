class CreateSpreeSheets < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_sheets do |t|
      t.string :name
      t.integer :rows
      t.integer :header_row
      t.timestamps
    end

    # add_index :spree_sheets, :name

  end
end
