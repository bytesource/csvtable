require 'digest'

class String
  # Checks if String represents an Integer.
  def is_i?
    !!(self =~ /^[-+]?[0-9,]+$/)
  end

  # Checks if String represents a Float.
  def is_f?
    !!(self =~ /^[-+]?[0-9,]+\.[0-9]+$/)
  end

  def is_n?
    self.is_i? || self.is_f?
  end
end


class CSVTable
  attr_reader :headers, :fields 
  attr_reader :data_hash, :executed 
  attr_reader :delimiter, :name

  @default_separator = "@"
  @default_delimiter = ","

  # Class methods are singleton methods on a CLASS OBJECT.
  class << self
    attr_accessor :default_separator
    attr_accessor :default_delimiter
  end

  def initialize path, options = {}
    raise ArgumentError, "File does not exist!" unless File.exists?( path )
    raise Exception, "Can only read csv files" unless can_read?( path)

    @separator  = options[:separator] || CSVTable.default_separator
    @delimiter  = options[:delimiter] || CSVTable.default_delimiter

    data = prepare File.open(path) 

    @name       = table_name(path)
    @headers    = extract_headers(data)
    @fields     = extract_fields(data)

    @data_hash  = make_hash(@fields)
    @executed   = false
  end


  def can_read? path
    !!(/.*\.csv$/ =~ path)
  end


  def execute connection, name=nil
    begin
      raise Exception, "Data already copied to table #{@name}!" if @executed

      name ||= @name
      # Create a dataset
      dataset = connection[name]
      data    = fields_headers_hash do |row| 
        row.merge(:hash => @data_hash)
      end

      raise Exception, "Data already in table. Abort!" if data_already_in_table? dataset
      # Populate the table
      data.map do |row|
        dataset.insert(row)
      end
      # $! = Global variable set to the last exception raised.
      @executed = true unless $!
    ensure
      # connection.disconnect
    end
  end

  def executed?
    @executed
  end


  private

  def data_already_in_table? dataset
    stored_hashes = dataset.map {|row| row[:hash]}

    stored_hashes.find {|value| value == @data_hash}
  end


  # Pattern
  # path/to/file/TableName@FileName.csv --> :tablename
  def table_name path
    dir, file       = File.split(path)
    prefix, postfix = file.split(@separator)
    raise Exception, "No table name given!" if blank?(prefix)

    if prefix.match(/\./)
      # There was nothing to split avove (separator not given),
      # to we got back the filename (xxx.type), unaltered.
      prefix, filetype = prefix.split('.')
    end

    prefix.gsub(/[-\s]+/, '_').downcase.to_sym 
  end


  def prepare file
    array = []
    file.each_line do |line|
      # Valid lines are identified by having some text with @delimiter in between.
      # Why use regex.source:
      # http://stackoverflow.com/questions/2648054/ruby-recursive-regex
      get_line = Regexp.new(".+#{@delimiter}.+")
      next unless line.match(/#{get_line.source}/) 
      # Remove end of line char, split at @delimiter
      get_word = Regexp.new("\s*#{@delimiter}\s*")
      result = line.chomp.split(/#{get_word.source}/).map do |word|
        # Remove all escaped quotes (\"), strip leading and trailing whitespace
        word.gsub(/"/,"").strip
      end
      array << result
    end
    array
  end


  def extract_headers raw_data
    raw_data[0].map do |header|
      formatr(header)
    end
  end


  def formatr word
    word.gsub(/[-\s]+/, "_").downcase.to_sym
  end


  def extract_fields raw_data
    fields = raw_data.drop(1).map do |row|
      values = row.map do |val|
        result = str_to_num(val)
        replace_if_blank(result)
      end
      values << nil if values.size < @headers.size
      values
    end
    fields
  end


  def replace_if_blank value, new_value=nil
    if blank?(value.to_s)
      new_value
    else
      value
    end
  end


  def blank? word
    word.empty? || !!(word =~ /^\s+$/)
  end


  def str_to_num s
    if s.is_i?
      s.to_i
    elsif s.is_f?
      s.to_f
    else
      s
    end
  end

  #  [ ["apple", "It's delicious", 23.3] ]
  #  => [ {:item=>"apple", :description=>"It's delicious", :price=>23.3} ]
  def fields_headers_hash &block
    result = @fields.inject([]) do |acc, line|
      temp = to_hash(@headers, line)

      block_given? ? acc << yield(temp) : acc << temp
    end
    result 
  end

  def to_hash keys, vals
    zip_array = keys.zip(vals)
    Hash[*zip_array.flatten]
  end

  def make_hash data  
    Digest::SHA2.hexdigest(data.to_s)
  end
end

