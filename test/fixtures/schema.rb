ActiveRecord::Schema.define do

  create_table "products", :force => true do |t|
    t.column "name",          :string, :limit => 100
    t.column "price",         :float
    t.column "sales_volume",  :integer
    t.column "launch_date",   :datetime
  end


end