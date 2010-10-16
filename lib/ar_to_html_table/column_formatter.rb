# ==Column Formatters
#
# Each cell value (attribute in a row) is formatted on output.  This module
# defines a series of formatters.  A formatter is any method with a signature
# of:
#
# <tt>def method(cell_value, options)</tt>
#
# Hence any method already in scope at the time of formatting is available as well.
# For example <tt>number_with_delimeter</tt> and friends are valid formatters.
module ArToHtmlTable
  module ColumnFormatter
    
    def self.included(base) #:nodoc:
      #base.class_eval do
      #  extend  ActiveSupport::Memoizable
      #  memoize :integer_with_delimiter
      #  memoize :float_with_precision
      #  memoize :currency_without_sign
      #end
    end
    
    MIN_PERCENT_BAR_VALUE   = 2.0   # Below which no bar is drawn
    REDUCTION_FACTOR        = 0.80  # Scale the bar graps so they have room for the percentage number in most cases
    
    # If the value is #blank? then display a localized
    # version of "Not Set".
    #
    # ====Examples
    #
    #   # Given a value <em>nil</em> the following will be output
    #   # if the locale is set to "en" and the default translations
    #   # are not changed:
    #   (Not Set)
    #
    #   val: the value to be formatted
    #   options: formatter options 
    def not_set_on_blank(val, options)
      if options[:cell_type] == :th
        val
      else
        val.blank? ? I18n.t(options[:not_set_key]) : val
      end
    end

    def group_not_set_on_blank(val, options) #:nodoc:
      # Need more context to do this
    end

    # If the value is #blank? then display a localized
    # version of "Unknown".
    #
    # ====Examples
    #
    #   # Given a value _nil_ the following will be output
    #   # if the locale is set to "en" and the default translations
    #   # are not changed:
    #   (Unknown)
    #
    #   val: the value to be formatted
    #   options: formatter options
    def unknown_on_blank(val, options)
      if options[:cell_type] == :th
        val
      else    
        val.blank? ? I18n.t(options[:unknown_key]) : val
      end
    end

    # Interprets an integer as a duration and outputs the duration
    # in the format hh:mm:ss
    #
    # ====Examples
    #
    #   # Given a value of 3600, the formatter will output
    #   00:05:00
    #
    #   val: the value to be formatted
    #   options: formatter options
    def seconds_to_time(val, options)
      hours = val / 3600
      minutes = (val / 60) - (hours * 60)
      seconds = val % 60
      (minutes += 1; seconds = 0) if seconds == 60
      (hours += 1; minutes = 0) if minutes == 60
      "#{"%02d" % hours}:#{"%02d" % minutes}:#{"%02d" % seconds}"
    end
  
    # Interprets an integer as a number of hours and outputs the value
    # in the format hh:00
    #
    # ====Examples
    #
    #   # Given a value of 11, the formatter will output
    #   11:00
    #
    #   val: the value to be formatted
    #   options: formatter options
    def hours_to_time(val, options)
      "#{"%02d" % val}:00"
    end

    # Interprets an integer as a percentage with a single
    # digit of precision. Shim for <tt>#number_to_percentage</tt>
    #
    # ====Examples
    #
    #   # Given a value of 48, the formatter will output
    #   48.00%
    #
    #   val: the value to be formatted
    #   options: formatter options
    def percentage(val, options)
      number_to_percentage(val ? val.to_f : 0, :precision => 1)
    end
  
    # Formats a number as an integer with a delimiter.  If Cldr::Format
    # module is included into I18n then the value is localized (recommended
    # for multilanguage applications).  If not, number_with_delimiter is used
    # formatting.
    #
    # ====Examples
    #
    #   # Given a value of 1245 and no Cldr::Format, the formatter will output
    #   1,345
    #
    #   val: the value to be formatted
    #   options: formatter options
    #
    #-- 
    # TODO this should be done just once at instantiation but we have a potential
    # ordering issue  since I18n initializer may not have run yet (needs to be checked)
    def integer_with_delimiter(val, options = {})
      if I18n::Backend::Simple.included_modules.include? Cldr::Format 
        I18n.localize(val.to_i, :format => :short)
      else 
        number_with_delimiter(val.to_i)
      end
    end

    # Formats a number as an float with a delimiter and precision of 1.
    #
    # ====Examples
    #
    #   # Given a value of 1245, the formatter will output
    #   1,345.0
    #
    #   val: the value to be formatted
    #   options: formatter options
    def float_with_precision(val, options)
      number_with_precision(val.to_f, :precision => 1)
    end

    # Formats a number as an float with a delimiter and precision of 2.
    #
    # ====Examples
    #
    #   # Given a value of 1245, the formatter will output
    #   1,345.00
    #
    #   val: the value to be formatted
    #   options: formatter options
    def currency_without_sign(val, options)
      number_with_precision(val.to_f, :precision => 2)
    end
  
    # Formats a number as a horizontal CSS-based bar followed
    # by the number formatted as a percentage.
    #
    # ====Examples
    #
    #   # Given a value of 11, the formatter will output
    #   <tt><div class="hbar" style="width:#{width}%">&nbsp;</div>
    #   <div>11%</div></tt>
    #
    #   val: the value to be formatted
    #   options: formatter options
    def bar_and_percentage(val, options)
      if options[:cell_type] == :td
        width = val * bar_reduction_factor(val)
        bar = (val.to_f > MIN_PERCENT_BAR_VALUE) ? "<div class=\"hbar\" style=\"width:#{width}%\">&nbsp;</div>" : ''
        bar + "<div>" + percentage(val, :precision => 1) + "</div>"
      else
        percentage(val, :precision => 1)
      end
    end
    
  private
    def bar_reduction_factor(value)
      case value
        when 0..79  then  REDUCTION_FACTOR
        when 80..99 then  0.6
        else 0.3
      end
    end  
  end
end