require File.dirname(__FILE__) + '/html_table/column_formatter.rb'
require File.dirname(__FILE__) + '/html_table/table_formatter.rb'
require File.dirname(__FILE__) + '/html_table/html_table.rb'
require File.dirname(__FILE__) + '/column_formats.rb'

Array.send :include, HtmlTable
ActiveRecord::Base.send :include, ColumnFormats
I18n.load_path += Dir[ File.join(File.dirname(__FILE__), 'locale', '*.{rb,yml}') ]
