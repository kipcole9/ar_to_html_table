# Adds method to Array to allow output of html tables - only works
# if the array is an ActiveRecord result set. See HtmlTable::TableFormatter
module HtmlTable
  module Model
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end
  
    module InstanceMethods
      # Renders an ActiveRecord result set into an HTML table
      #
      # ====Examples
      #
      #   # Render all products as an HTML table
      #   Product.all.to_table
      # 
      # See HtmlTable::TableFormatter for options.
      def to_table(options = {})
        @formatter = HtmlTable::TableFormatter.new(self, options)
        @formatter.to_html
      end
    end
  
    module ClassMethods

    end
  end
end
