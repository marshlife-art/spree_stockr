class CreateSpreeSheets < ActiveRecord::Migration[5.2]
  def change
    create_table :spree_sheets do |t|
      t.integer :status
      t.string :name
      t.integer :rows
      t.integer :header_row
      if ActiveRecord::Base.connection.adapter_name == 'postgresql'
        t.jsonb :data, null: false, default: {}
      else
        t.json :data, null: false, default: {}
      end
      t.timestamps
    end

    # add_index :spree_sheets, :name

  end
end
