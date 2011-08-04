require 'sequel'

class DBTable

  class << self
    attr_accessor :table_classes
  end

  @table_classes = {} 

  attr_accessor :connection_info
  

  def initialize info
    @connection_info = info
  end

  def connect
    Sequel.connect(@connection_info)
  end

  def self.name
    super.to_s.gsub!(/Table/,'').downcase.to_sym
  end


  

  def self.inherited(subclass)
    # DBTable.table_classes << subclass
    @table_classes = DBTable.table_classes.merge(subclass.name => subclass)
  end
  
end


class CodonsTable < DBTable

  @table_info
  

  def initialize &block

    @table_info = block || lambda do
    primary_key :id, :allow_null => false
    Integer     :item
    String      :description
    Float       :price
    end
  end

  def create_table connection
    name = CodonsTable.name
    unless connection.table_exists?(name)
      connection.create_table name do
        @table_info.call
        String      :hash
        index       :hash
      end
    end
  end
end
