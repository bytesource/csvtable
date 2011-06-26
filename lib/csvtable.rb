class String
  # Checks if String represents an Integer.
  def is_i?
    !!(self =~ /^[-+]?[0-9]+$/)
  end

  # Checks if String represents a Float.
  def is_f?
    !!(self =~ /^[-+]?[0-9]+\.[0-9]+$/)
  end

  def is_n?
    self.is_i? || self.is_f?
  end
end


class CSVTable
  attr_accessor :name, :headers, :fields
  attr_reader :executed


  def initialize path
    raise ArgumentError, "File does not exist" unless File.exists?( path )
    raise Exception, "Can only read csv files" unless can_read?( path)

    data = prepare File.open(path) 

    @name       = table_name(path)
    @headers    = extract_headers(data)
    @fields     = extract_fields(data)
    @executed   = false
  end


  def can_read? path
    !!(/.*\.csv/ =~ path)
  end


  def execute connection, name=nil
    raise Exception, "Data already copied to table #{@name}!" if @executed

    name ||= @name
    # Create a dataset
    table_name = connection[name]
    data  = fields_hash(@fields)

    # Populate the table
    data.map do |row|
      insert_data(table_name, row)
    end
    # $! = Global variable set to the last exception raised.
    @executed = true unless $!
  end


  private
  # Expects a Sequel dataset
  def insert_data dataset, data_row
    dataset.insert(data_row)
  end


  # Pattern
  # path/to/file/TableName_FileName.csv --> tablename
  def table_name path
    # 1) match:    --> /TableName_
    # 2) gsub:     --> TableName
    # 3) downcase: --> tablename
    # 4) to_sym:   --> :tablename
    path.match(/\/[^\/]+_/)[0].gsub(/^.|.$/,'').downcase.to_sym
  end


  def prepare file
    array = []
    file.each_line do |line|
      # Valid lines are identified by having some text with a comma in between.
      next unless line.match(/.+,.+/) 
      # Remove end of line char, split at comma
      result = line.chomp.split(/,\s*/).map do |word|
        # Remove all quotes (\")
        word.gsub(/"/,"")              
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
    word.gsub(/\s+/, "_").downcase
  end


  def extract_fields raw_data
    fields = raw_data.drop(1).map do |row|
      values = row.map do |val|
        result = replace_if_blank(val)
        result = str_to_num(result)
        result
      end

      values << "NULL" if values.size < @headers.size
      values
    end
    fields
  end


  def replace_if_blank value, new_value="NULL"
    if blank?(value)
      new_value
    else
      value
    end
  end


  def blank? word
    word.empty? || !!(word =~ /^\s+$/)
  end


  def str_to_num num_as_string
    if num_as_string.is_i?
      num_as_string.to_i
    elsif num_as_string.is_f?
      num_as_string.to_f
    else
      num_as_string
    end
  end

  #  [ ["apple", "It's delicious", 23.3] ]
  #  => [ {"item"=>"apple", "description"=>"It's delicious", "price"=>23.3} ]
  def fields_hash fields
    hash = fields.inject([]) do |result, line|
      result << to_hash(headers, line) 
    end
    hash
  end


  def to_hash keys, vals
    zip_array = keys.zip(vals).flatten
    Hash[*zip_array]
  end
end






