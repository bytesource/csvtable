# Usage:
# sovonex@sovonex:~/Desktop/temp/csv/test$ rspec csvtable_spec.rb

require File.expand_path('../lib/csvtable')

describe CSVTable do

  before(:each) do
    @file = "/DNA@check.csv"
    @path_to = File.expand_path('tables/')
    @path = @path_to + @file
    # Item,Description,Price
    # 1, "This is a great product"
    # ,"This product is not so good",23.4
    # 3,,34.1
    # 4,alles komplett,23
    @table = CSVTable.new(@path)
  end

  describe "Opening a file: " do

    it "should raise an exception if the file does not exist" do
      @wrong_path = "/dummy/path/to/" + @file
      lambda do
        CSVTable.new(@wrong_path)
        # http://stackoverflow.com/questions/1722749/how-to-use-rspecs-should-raise-with-any-kind-of-exception
      end.should raise_error
    end

    it "should raise an exception if the file has the wrong file type" do
      @other_type = "DNA@check.txt"
      @wrong_file_path = @path_to + @other_type
      lambda do
        CSVTable.new(@wrong_file_path)
      end.should raise_error
    end
  end



  describe "instance variables" do

    it "should have the right name" do
      @table.name.should == :dna
    end

    it "should set @executed to 'false'" do
      @table.executed.should == false
    end

    it "should set @data_hash to the correct hash value" do

      data = @table.fields.to_s

      test_hash = Digest::SHA2.hexdigest(data)

      @table.send(:make_hash, data).should == test_hash
    end
  end


  describe "instance methods" do
    it "'replace_if_blank' should return the right value" do
      # http://stackoverflow.com/questions/4271696/rspec-rails-how-to-test-private-methods-of-controllers
      # Use send(:private_method) to call private method:
      @table.send(:replace_if_blank, "    ").should == nil
    end

    it "'fields_hash' should convert an array of arrays into an array of hashes" do

      @array = [ ["apple", "It's delicious", 23.3] ] 

      result = @table.send(:fields_hash, @array)
      
      hash = {:hash => @table.data_hash}
      with_hash = [] <<  {:item=>"apple", :description=>"It's delicious", :price=>23.3}.merge(hash)
      result.should == with_hash
    end
  end

  describe "insert data into database: " do
    before(:each) do

      # Using before(:all) instead of before(:each), to avoid repeated initialization of 'DB'
      # @table from above is not recognized anymore. Therefore I had to create another CSVTable object:
      # @file = "/DNA@check.csv"
      # @path_to = File.expand_path('tables/')
      # @path = @path_to + @file

      # @table = CSVTable.new(@path)

      require "sequel"
      # http://sequel.rubyforge.org/rdoc/files/doc/cheat_sheet_rdoc.html
      # Open an SQLite memory database
      DB = Sequel.sqlite

      DB.create_table @table.name do
        primary_key :id
        Integer     :item
        String      :description
        Float       :price
        String      :hash
      end

    end

    describe "on success" do

      it "should insert all fields into the table" do
        @table.execute DB
        DB[@table.name].count.should == 4
      end

      it "should set @executed to 'true'" do
        @table.execute DB
        @table.executed?.should be_true
      end
    end

    describe "on failure: " do

      it "one instance should only be able to insert the data once" do
        @table.execute DB
        lambda do
          @table.execute(DB)
          DB[@table.name].count.should == 4
        end.should raise_error(Exception, "Data already copied to table #{@table.name}!")
      end

      it "should NOT set @executed to 'true' if an exception is raised during data entry" do
        lambda do
          @table.execute DB, :test  # wrong table name
        end.should raise_error
        @table.executed?.should_not be_true
      end

      it "should not allow another instance to insert the same data" do
        @table.execute DB
        @table2 = CSVTable.new(@path)
        lambda do
          @table2.execute(DB)
          DB[@table.name].count.should == 4
        end.should raise_error(Exception, "Data already in table. Abort!")
      end

      it "should not allow to enter the same data again from another file with a different name" do
        @table.execute DB
        @exact_copy = "/DNA@exact_copy.csv"
        @new_path   = @path_to + @file
        @table2 = CSVTable.new(@new_path)
        lambda do
          @table2.execute(DB)
          DB[@table.name].count.should == 4
        end.should raise_error(Exception, "Data already in table. Abort!")
      end
    end
  end
end
