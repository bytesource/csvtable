# Using autoload:
# autoload :String,    'path'
# autoload :CSVTable,  'path'

# http://blog.8thlight.com/articles/2007/10/08/micahs-general-guidelines-on-ruby-require
# Add lib directory to the ruby search path:
$: << File.join(File.expand_path(File.dirname(__FILE__)), "lib")

require 'csvtable'

csv_path = File.join(File.expand_path(File.dirname(__FILE__)), "test", "tables")

check_path = csv_path + "/DNA@check.csv"


table = CSVTable.new(check_path)

# ======================================================================
# Opening a connection

require "sequel"

# http://sequel.rubyforge.org/rdoc/files/doc/cheat_sheet_rdoc.html
# Open an SQLite memory database
DB = Sequel.sqlite

# Connectiong to MYSQL
# (sudo apt-get install libmysqlclient-dev)
# (gem install mysqlplus)
# DB = Sequel.connect(:adapter  =>'mysql', 
#                     :host     =>'localhost', 
#                     :database =>'plastronics', 
#                     :user     =>'root', 
#                     :password =>'moinmoin')

unless DB.table_exists?(table.name)
  DB.create_table table.name do
    primary_key :id, :allow_null => false
    Integer     :item
    String      :description
    Float       :price
    String      :hash
  end
end

puts "Path to csv file: #{check_path}"
puts "Table name: #{table.name}"
puts "@fields: #{table.fields}"
puts "@data_hash: #{table.data_hash}"
table.execute DB

puts "Testing database:"
puts DB.schema(:dna)
puts DB[:dna].all
