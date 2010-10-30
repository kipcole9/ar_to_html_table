module ArToHtmlTable
  class TableFormatter
    attr_accessor           :html, :table_columns, :klass, :merged_options, :rows, :totals
    attr_accessor           :column_cache

    EXCLUDE_COLUMNS         = [:id, :updated_at, :created_at, :updated_on, :created_on]
    CALCULATED_COLUMNS      = /(percent|percentage|difference|diff)_of_(.*)/
    DEFAULT_OPTIONS         = {
        :exclude      => EXCLUDE_COLUMNS, 
        :exclude_ids  => true, 
        :odd_row      => "odd", 
        :even_row     => "even", 
        :totals       => true,
        :total_one    => 'tables.total_one',
        :total_many   => 'tables.total_many',
        :unknown_key  => 'tables.unknown',
        :not_set_key  => 'tables.not_set'
    }
    
    # Initialize a table formatter.  Not normally called directly since
    # Array#to_table takes care of this.
    #
    #   results: the value to be formatted
    #   options: formatter options
    #
    # ====Options
    #
    #   :include        Array of attributes to include in the table. Default is all attributes excepted :excluded ones.
    #   :exclude        Array of attributes to exclude from the table. Default is [:id, :updated_at, :created_at, :updated_on, :created_on]
    #   :exclude_ids    Exclude attributes with names ending in '_id'. Default is _true_
    #   :sort           A proc invoked to sort the rows before output.  Default is not to sort.
    #   :heading        Table heading places in the first row of a table
    #   :caption        Table caption applied with <caption> markup
    #   :odd_row        CSS Class name of the odd rows in the table.  Default is _odd_
    #   :even_row       CSS Class name of the even rows.  Default is _even_
    #   :totals         Include a total row if _true_.  Default is _true_
    #   :total_one      I18n key for displaying a table footer when there is one row.  Default _tables.total_one_
    #   :total_many     I18n key for displaying a table footer when there are > 1 rows. Default is _tables.total_many_
    #   :unknown_key    I18n key for displaying _Unknown_. Default is _tables.unknown_
    #   :not_set_key    I18n key for displaying _Not Set_.  Default is _tables.no_set_ 
    def initialize(results, options)
      raise ArgumentError, "[to_table] First argument must be an array of ActiveRecord rows" \
        unless  results.try(:first).try(:class).try(:descends_from_active_record?) ||
                results.is_a?(ActiveRecord::NamedScope::Scope)
                
      raise ArgumentError, "[to_table] Sort option must be a Proc" \
        if options[:sort] && !options[:sort].is_a?(Proc)
          
      @klass          = results.first.class
      @rows           = results
      @column_order   = 0
      @merged_options = DEFAULT_OPTIONS.merge(options)
      @table_columns  = initialise_columns(rows, klass, merged_options)
      @totals         = initialise_totalling(rows, table_columns)
      results.sort(options[:sort]) if options[:sort]
      @merged_options[:rows] = results
      @html = Builder::XmlMarkup.new(:indent => 2)
      @column_cache   = {}
    end

    # Render the result set to an HTML table using the
    # options set at object instantiation.
    #
    # ====Examples
    #
    #   products = Product.all
    #   formatter = ArToHtmlTable::TableFormatter.new(products)
    #   formatter.to_html
    def to_html
      options = merged_options
      table_options = {}
      html.table table_options do
        html.caption(options[:caption]) if options[:caption]
        output_table_headings(options)
        output_table_footers(options)
        html.tbody do
          rows.each_with_index do |row, index|
            output_row(row, index, options)
          end
        end
      end 
    end

  protected
    # Outputs colgroups and column headings
    def output_table_headings(options)
      # Table heading
      html.colgroup do
        table_columns.each {|column| html.col :class => column[:name] }
      end
    
      # Column groups
      html.thead do
        html.tr(options[:heading], :colspan => columns.length) if options[:heading]
        html.tr do
          table_columns.each do |column| 
            html_options = {}
            html_options[:class] = column[:class] if column[:class]
            html.th(column[:label], html_options)
          end
        end
      end
    end

    # Outputs one row
    def output_row(row, count, options)
      html_options = {}
      html_options[:class] = (count.even? ? options[:even_row] : options[:odd_row])
      html_options[:id] = row_id(row) if row[klass.primary_key]
      html.tr html_options  do
        table_columns.each {|column| output_cell(:td, row, column, options) }
      end
    end

    # Outputs table footer
    def output_table_footers(options)
      output_table_totals(options) if options[:totals] && rows.length > 1
    end

    # Output totals row (calculations)
    def output_table_totals(options)
      return unless table_has_totals?
      html.tfoot do
        html.tr do
          first_column = true
          table_columns.each do |column| 
            value = first_column ? first_column_total(options) : totals[column[:name].to_s]
            output_cell(:th, value, column, options)
            first_column = false
          end
        end
      end    
    end

    # Outputs one formatted cell
    def output_cell(cell_type, row_or_value, column, options = {})
      formatter_options = options.reverse_merge({:cell_type => cell_type, :column => column})
      if row_or_value.class.respond_to? :descends_from_active_record?
        result = row_or_value.format_column(column[:name], formatter_options)
      else
        result = klass.format_column(column[:name], row_or_value, formatter_options)
      end
      html.__send__(cell_type, (column[:class] ? {:class => column[:class]} : {})) do
        html << result.to_s
      end
    end

  private
    # Craft a CSS id
    def row_id(row)
      "#{klass.name.underscore}_#{row[klass.primary_key]}"
    end
  
    def table_has_totals?
      !totals.empty?
    end
  
    def initialise_columns(rows, model, options)
      options[:include] = options[:include].map(&:to_s) if options[:include]
      options[:exclude] = options[:exclude].map(&:to_s) if options[:exclude]
      add_calculated_columns_to_rows(rows, options)
      requested_columns = columns_from_row(rows.first)
      columns = requested_columns.inject([]) do |definitions, column|
        definitions << column_definition(column) if include_column?(column, options)
        definitions
      end
      columns.sort{|a, b| a[:order] <=> b[:order] }
    end

    # Return a hash of hashes
    # :sum => {:column_name_1 => value, :column_name_2 => value}
    def initialise_totalling(rows, columns)
      columns.inject({}) do |totals, column|
        case column[:total]
          when :sum
            totals[column[:name]] = rows.make_numeric(column[:name]).sum(column[:name])
          when :mean, :average, :avg
            totals[column[:name]] = rows.make_numeric(column[:name]).mean(column[:name])
          when :count
            totals[column[:name]] = rows.make_numeric(column[:name]).count(column[:name])
          when :trend
            totals[column[:name]] = rows.make_numeric(column[:name]).trend(column[:name])
        end
        totals
      end  
    end
  
    def first_column_total(options)
      if rows.count > 1
        I18n.t(options[:total_many], :count => rows.count)
      else
        I18n.t(options[:total_one], :count => rows.count)
      end
    end
  
    def column_definition(column)
      @column_order += 1
      format_options = klass.format_of(column)
      return {
        :name       => column,
        :label      => klass.human_attribute_name(column),
        :class      => format_options[:class],
        :order      => format_options[:order] || @column_order,
        :total      => format_options[:total]
      }
    end
  
    def columns_from_row(row)
      row.attributes.inject([]) {|columns, (k, v)| columns << k.to_s }
    end

    # Decide if the given column is to be displayed in the table
    def include_column?(column, options)
      return options[:include].include?(column) if options[:include]
      return false if options[:exclude] && options[:exclude].include?(column)
      return false if options[:exclude_ids] && column.match(/_id\Z/)  
      true
    end
  
    def add_calculated_columns_to_rows(rows, options)
      options.each do |k, v|
        if match = k.to_s.match(CALCULATED_COLUMNS)
          raise ArgumentError, "[to_table] Total value must not be 0 for percentage_of" if match[1] =~ /percent/ && v.to_f == 0
          rows.each do |row|
            row[k.to_s] = case match[1]
              when 'percent', 'percentage'
                row[match[2]].to_f / v.to_f * 100
              when 'difference', 'diff'
                row[match[2]].to_f - v.to_f
              else
                raise ArgumentError, "[to_table] Invalid calculated column '#{match[1]}' for '#{match[2]}'"
            end
          end
        end
      end  
    end
  
  end
end