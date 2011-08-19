require 'sequel'

class DBTable

  class << self
    attr_accessor :table_classes, :database_info
  end

  @table_classes = {} 

  

  def initialize info = {}
    DBTable.database_info = info
    puts "info: #{info}"
    puts "@database_info: #{@database_info}"
  end

  def connect
    Sequel.connect(DBTable.database_info)
  end

  def self.name
    super.gsub!(/Table/,'').downcase.to_sym
  end

  def self.inherited(subclass)
    # DBTable.table_classes << subclass
    @table_classes = self.table_classes.merge(subclass.name => subclass)
  end
  
end


class CodonsTable < DBTable

  attr_accessor :table_info, :database_info
  

  def initialize &block

    @table_info = block || lambda do
    primary_key :id, :allow_null => false
    Integer     :item
    String      :description
    Float       :price
    end

    @database_info = DBTable.database_info
  end

  
  def create_table
    name = CodonsTable.name
    puts "CodonsTable, @database_info: #{@database_info}"
    db   = connect
    puts "create_table, @table_info: #{@table_info}"
    unless db.table_exists?(name)
      db.create_table name do
        instance_eval @table_info
        String      :hash
        index       :hash
      end
    end
  end
end
