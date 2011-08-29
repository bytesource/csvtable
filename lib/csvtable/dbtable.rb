# GOAL
# The following initialization of a CSVParser should be possible:

# require 'dbtable'

# db = database.new
# 
# csvparser.new(path, db :table_name => :name)
# 
# # alternatively (haven't thought this through yet):
# csvparser.new do
#   path   'path/to/table.csv'
#   db     database.new        # don't pass in the database, but open in inside 'initialize'
#   name   :name
# end

# features of either of the two above ways of initialization:
# 1) csvparser calls the right subclass of database based on :table_name
#    -- the database object stores all subclasses in map using 'self.inherited', 
#       so subclasses can be stored in a file are automatically available.
#    -- :table_name is optional. the name of the table can also be deducted from the file name, 
#       provided it follows a certain pattern.
#    -- database provides a default connection info, 
#       which can be changed before passing the database object to csvparser 
#    -- each subclass of database represents a table in a database with the same name. each object provides
#       the information necessary to store the data of the csv file into the database table.

# additional thoughts:
# -- Will probably parse the csv file with Parset using the quasi standard ebnf notation of csv files.
# -- Adding a hash to an existing table might not be preferable in many cases. Therefore thinking about
#    making the hash optional and storing it either in a text file or a new table called hash that has two colums:
#    -- table_name
#    -- hash

require 'sequel'

class DBTable # rename to Database

  class << self
    attr_accessor :table_classes, :default_db
  end

  @table_classes = {} 
  @default_db    = {:adapter  =>'mysql', 
                    :host     =>'localhost', 
                    :database =>'plastronics', 
                    :user     =>'root', 
                    :password =>'xxx'}

  def initialize
    @database = DBTable.default_db
    puts "@database: #{@database}"
  end

  def connect
    Sequel.connect(@database)
  end

  def self.name   # remove, as we use each sublcasses' real name
    super.gsub!(/Table/,'').downcase.to_sym
  end

  def self.inherited(subclass)
    # DBTable.table_classes << subclass
    @table_classes = self.table_classes.merge(subclass.name => subclass)
  end
  
end


class CodonsTable < DBTable   # Rename CodonsTable to Codons to reflect the real table name

  attr_accessor :table_info, :database
  

  def initialize &block

    @table_info = block || lambda do
    primary_key :id, :allow_null => false
    Integer     :item
    String      :description
    Float       :price
    end

    @database = DBTable.default_db
  end

  
  def create_table
    name = CodonsTable.name
    puts "CodonsTable, @database: #{@database}"
    db   = connect
    puts "create_table, @table_info: #{@table_info}"
    unless db.table_exists?(name)
      db.create_table name do
        puts "@table_info inside block: #{@table_info}" # @table_infor is nil here. Need to investigate this issue.
        @table_info.call
        String      :hash
        index       :hash
      end
    end
  end
end
