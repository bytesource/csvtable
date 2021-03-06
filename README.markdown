# CSVTable

### A Ruby class for entering data from a CSV file into a database.

CSVTable reads a csv file from a given path storing its headers and fields.
The csv data can then be entered into a corresponding database using the CSVTable#execute method.
[Sequel](http://sequel.rubyforge.org/) is used as the ORM between CSVTable and the database.

## Depreciated

The use of this library has been depreciated in favor of [RStore](https://github.com/bytesource/rstore), which is standard-compliant, more flexible and much easier to use.

`RStore` is available on RubyGems and can therefore be installed like this:

``` bash
gem install rstore
```

## Conventions

### CSV File

#### CSV Data Format

CSVTable does not deal with every csv format out there.
It is therefore required for the csv file to adhere to the following conventions:

* Header names can be enclosed in quotes but don't need to.
* Header names can be uppercase or lowercase (will be converted to lowercase).
* Header names can consist of several words (whitespace and hyphens will be converted to underscores).
* Field data can be missing or be empty (" ").
* There must be no whitespace between data fields and a delimiter.
* The following properties are not allowed:
  * Missing headers
  * Line breaks in headers or field data
  * Single-column csv files
  * Delimiters in data fields, unless every single one has a whitespace either before or after it.


#### Table Name
* The file name must be prefixed with the name of the database table, followed by a separator (default: @)
* If no separator is given, the table name defaults to the file name.
* The prefix can be both uppercase or lowercase.

#### Headers
* Header names must match their corresponding column names.
* Header names can be both uppercase or lowercase.

#### Fields
* If a String value represents an Integer, it is converted into an Integer.
* If a String value represents a Float, it is converted into a Float.
* If a value is missing at the end, it is set to nil.
* If a value is missing anywhere else, it is set to a replacement value, nil by default.




### Database Table

#### Table Name
* The table name matches the (lowercase) prefix of the csv file name.

#### Column Names
* Column names match the header names and are lowercase.

#### :hash Column
* Every table required an additional column :hash of type :String.
* The :hash column ensures that the same data cannot be added twice (see also "Data Integrity" below).


## Data Integrity

* On object creation a SHA2 hash on the csv file's fields data is created and stored in the CSVTable instance.
* This hash value will be stored in the :hash column of every data row of a given csv file.
* Before inserting any data into the database, the hashes already stored in the database are checked against the 
hash of data to be added.
* If the hash of the data to be added is found in the database, an exception is thrown and the (duplicate) data is not inserted.


## Usage

#### Sample CSV File
File name: DNA@check.csv

Contents:

```
Item,Description,Price
1, "This is a great product"
,"This product is not so good",23.4
3,,34.1
4,alles komplett,23
```

**Note**: Every field is missing a value at different positions.

1) Creating a database table using [Sequel](http://sequel.rubyforge.org/) ORM

``` ruby
require "sequel"

# Connect to MySQL database (many other databases supported by Sequel)
# (sudo apt-get install libmysqlclient-dev)
# (gem install mysqlplus)
DB = Sequel.connect(:adapter  =>'mysql', 
                    :host     =>'localhost', 
                    :database =>'sequencing', 
                    :user     =>'root', 
                    :password =>'xxx')

# Create database table
unless DB.table_exists?(:dna)
  DB.create_table :dna do
    primary_key :id, :allow_null => false
    Integer     :item
    String      :description
    Float       :price
    String      :hash
  end
end
```

**Notes**:

* Table name:   Matches the prefix of the csv file name. The table name is given in lowercase.
* Column names: Match the names of the headers. Column names are given in lowercase.
* Data types:   Match the valid types (string, integer, float, etc.) of the csv data.
* String hash   Required additional column for storing a unique hash that is used to identify duplicate data entries.


2) Initializing CSVTable object

~~~ ruby
table = CSVTable.new(path/to/DNA@check.csv)

# Testing
table.executed?
# => false
~~~


3) Inserting csv data into the database 

```ruby
table.execute DB

# Testing
table.executed?
# => true
puts DB[:dna].all
# {:id=>1, :item=>1,   :description=>"This is a great product",     :price=>nil,  :hash=>"c1fc89[...]5ef"}
# {:id=>2, :item=>nil, :description=>"This product is not so good", :price=>23.4, :hash=>"c1fc89[...]5ef"}
# {:id=>3, :item=>3,   :description=>nil,                           :price=>34.1, :hash=>"c1fc89[...]5ef"}
# {:id=>4, :item=>4,   :description=>"alles komplett",              :price=>23.0, :hash=>"c1fc89[...]5ef"}
```


4) Preventing duplicate data entry

```ruby
# Calling execute a second time on the same object throws an exception:
table.execute DB
# Exception: Data already copied to table dna!

# Trying to insert the same data from a different CSVTable object also throws an exception:
table2 = CSVTable.new(path/to/DNA@check.csv)
table2.executed?
# => false
table2.execute DB
# Exception: Data already in table. Abort!
```

5) Some options for customization

**Custom delimiter** 

If there are one or more commas inside the data fields, the csv file has to be saved using a different delimiter, such as a semicolon.
CSVTable uses as comma as the default delimiter, but you can choose a custom delimiter like so:

```ruby
# Setting custom delimiter for all instances of CSVTable:
CSVTable.default_delimiter = ";"

with_semicolon = "path/to/DNA@check_sc.csv"

table = CSVTable.new('with_semicolon')
table.delimiter
# => ;

# Setting customer delimiter for a single object:
with_vertical_bar = "path/to/DNA@check_vb.csv"

table2 = CSVTable.new('with_vertical_bar', :delimiter => '|')
table2.delimiter
# => |

# Using the wrong delimiter
table3 = CSVTable.new('with_vertical_bar', :delimiter => ";")
# Exception: Delimiter ';' not found in header row. 

```

**Notes**: 

* A custom file name separator can be chosen in the same way.
* In order to avoid mistakes, choosing a custom delimiter or separator has to be made explicit on creation of an object. Changing the value on the fly using an instance method is not possible.


## Afterword

This is my first attempt at programming in Ruby and it probably shows. For example, although typical Ruby makes heavy use of blocks, most of my instance method don't take a block parameter.
However, I am eager to constantly improve and therefore highly appreciate *any* suggestions that might help me make my code more idiomatic and robust.

