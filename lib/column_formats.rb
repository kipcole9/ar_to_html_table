# Module included into ActiveRecord at gem activation.  Includes methods
# to define column formats used when rendering an HTML table.
module ColumnFormats
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include InstanceMethods
    end
  end
  
  module InstanceMethods

  end
  
  module ClassMethods
    # Define a column format.
    #
    # ====Options
    #
    #   :order      Defines the column output order relative to other columns
    #   :total      Column totaling method
    #   :class      CSS Class to be added to the table cell
    #   :formatter  Formatter to be applied.  Default is #to_s.  A symbol or lambda.  Symbol can
    #               represent any method that accepts a value and options including methods in
    #               ActionView::Helpers::NumberHelper
    #
    # See HtmlTable::ColumnFormatter for formatter options.
    #
    # ====Examples
    #
    #   class Product < ActiveRecord::Base
    #     column_format :name,      :order => 1
    #     column_format :orders,    :total => :sum
    #     column_format :revenue,   :total => :sum, :order => 5, :class => 'right'
    #     column_format :age, 	    :total => :avg, :order => 20, :class => 'right', :formatter => :number_with_delimiter
    #   end
    def column_format(method, options)
      @attr_formats = (@attr_formats || default_formats).deep_merge({method.to_s => options})
    end
    alias :table_format :column_format

    # Retrieve a column format.
    #
    # ====Examples
    #
    #   # Given the following class definition
    #   class Product < ActiveRecord::Base
    #     column_format :name,      :order => 1
    #     column_format :orders,    :total => :sum
    #     column_format :revenue,   :total => :sum, :order => 5, :class => 'right'
    #     column_format :age, 	    :total => :avg, :order => 20, :class => 'right', :formatter => :number_with_delimiter
    #   end
    #
    #   Product.format_of(:name)
    #   => { :order => 1 }
    #
    #   Product.format_of(:revenue)
    #   => { :total => :sum, :order => 5, :class => 'right' }
    def format_of(name)
      @attr_formats ||= default_formats
      @attr_formats[name] || {}
    end
    
  private
    # Default column formats used in to_table for active_record
    # result arrays
    #
    # Hash options are:
    # => :class => 'class_name' # used to add a CSS class to the <td> element
    # => :formatter => A symbol denoting a method or a proc to be used to 
    #    format the data element.  It will be passed the element only.
    #
    def default_formats
      attr_formats = {}
      columns.each do |column|
        attr_formats[column.name] = case column.type
        when :integer, :float
          {:class => :right, :formatter => :number_with_delimiter}
        when :text, :string
          {}
        when :date, :datetime
          {}
        else
          {}
        end
      end
      attr_formats
    end
  end

end
