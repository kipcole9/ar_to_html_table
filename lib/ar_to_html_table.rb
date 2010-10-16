require File.dirname(__FILE__) + '/ar_to_html_table/column_formatter.rb'
require File.dirname(__FILE__) + '/ar_to_html_table/table_formatter.rb'
require File.dirname(__FILE__) + '/ar_to_html_table/column_formats.rb'
require File.dirname(__FILE__) + '/ar_to_html_table/model.rb'

Array.send :include, ArToHtmlTable::Model
ActiveRecord::Base.send :include, ArToHtmlTable::ColumnFormats
I18n.load_path += Dir[ File.join(File.dirname(__FILE__), 'locale', '*.{rb,yml}') ]

module ArToHtmlTable
  
end