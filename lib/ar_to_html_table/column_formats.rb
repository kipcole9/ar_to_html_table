# Module included into ActiveRecord at gem activation.  Includes methods
# to define column formats used when rendering an HTML table.
module ArToHtmlTable
  module ColumnFormats
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end
  
    module InstanceMethods
      # Invoke the formatter on a column.
      #
      # ====Examples
      #
      #   class Product < ActiveRecord::Base
      #     column_format :name,      :order => 1
      #     column_format :orders,    :total => :sum
      #     column_format :revenue,   :total => :sum, :order => 5, :class => 'right'
      #     column_format :age, 	    :total => :avg, :order => 20, :class => 'right', :formatter => :number_with_delimiter
      #   end
      # 
      #   # p = Product.first
      #   # p.age
      #   => 4346
      #
      #   # p.format_column(:age)
      #   => "4,346"
      #
      # ====Parameters
      #
      #   column_name:  A column (attribute) on the the model instance 
      def format_column(column_name)
        self.class.format_column(column_name, self[column_name])
      end
      alias :format_attribute :format_column
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
        options[:formatter] = ::ArToHtmlTable::TableFormatter.procify(options[:formatter]) if options[:formatter] && options[:formatter].is_a?(Symbol)
        @attr_formats = (@attr_formats || default_formats).merge({method.to_s => options})
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
        @attr_formats[name.to_s] || {}
      end
      
      # Invoke the formatter on a column.
      #
      # ====Examples
      #
      #   class Product < ActiveRecord::Base
      #     column_format :name,      :order => 1
      #     column_format :orders,    :total => :sum
      #     column_format :revenue,   :total => :sum, :order => 5, :class => 'right'
      #     column_format :age, 	    :total => :avg, :order => 20, :class => 'right', :formatter => :number_with_delimiter
      #   end
      #
      #   # Product.format_column(:age, 4346)
      #   => "4,346"
      #
      # ====Parameters
      #
      #   column_name:  A column (attribute) on the the model instance
      #   value: The value to be formatted
      def format_column(column_name, value)
        formatter = format_of(column_name)[:formatter]
        raise "Column #{column_name} has no configured formatter" unless formatter && formatter.is_a?(Proc)
        formatter.call(value, {})
      end
      alias :format_attribute :format_column
    
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
            { :class => :right, 
              :formatter => lambda {|*args| number_with_delimiter(args[0])} }
          when :text, :string
            { :formatter => lambda {|*args| args[0]} }
          when :date, :datetime
            { :formatter => lambda {|*args| args[0].to_s(:db)} }
          else
            { :formatter => lambda {|*args| args[0].to_s} }
          end
        end
        attr_formats
      end
    end
  end
end
