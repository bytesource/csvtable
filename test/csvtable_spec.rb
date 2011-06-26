# Usage:
# sovonex@sovonex:~/Desktop/temp/csv/test$ rspec csvtable_spec.rb

require '/home/sovonex/Desktop/temp/csv/lib/csvtable'

describe CSVTable do

  before(:each) do
    @file = "DNA_check.csv"
    @path_to = "/home/sovonex/Desktop/temp/csv/test/tables/" 
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
      @other_type = "DNA_check.txt"
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
  end


  describe "instance methods" do
    it "'replace_if_blank' should return the right value" do
      # http://stackoverflow.com/questions/4271696/rspec-rails-how-to-test-private-methods-of-controllers
      # Use send(:private_method) to call private method:
      @table.send(:replace_if_blank, "    ").should == "NULL"
    end

    it "'fields_hash' should convert an array of arrays into an array of hashes" do

      @array = [ ["apple", "It's delicious", 23.3] ] 

      result = @table.send(:fields_hash, @array)
      result.should == [ {"item"=>"apple", "description"=>"It's delicious", "price"=>23.3} ]
      # result.is_a?(Arrray)
      # result.size.shoruld == 1
      # result.each do  |element|
      #   element.is_a? (Hash).should be_true
      #   element.size.should == 3
      # end
    end
  end

  describe "insert data into database: " do
    before(:all) do

      # Using before(:all) instead of before(:each), to avoid repeated initialization of 'DB'
      # @table from above is not recognized anymore. Therefore I had to create another CSVTable object:
      @path = "/home/sovonex/Desktop/temp/csv/test/tables/DNA_check.csv"
      @table = CSVTable.new(@path)

      require "sequel"
      # http://sequel.rubyforge.org/rdoc/files/doc/cheat_sheet_rdoc.html
      # Open an SQLite memory database
      DB = Sequel.sqlite

      DB.create_table @table.name do
        primary_key :id
        Integer     :item
        String      :description
        Float       :price
      end
    end

    describe "on success" do

      it "should insert all fields into the table" do
        @table.execute DB
        DB[@table.name].count.should == 4
      end

      it "should set @executed to 'true'" do
        @table.execute DB
        @table.executed.should be_true
      end
    end

    describe "on failure" do

      it "should not insert the same data a second time" do
        @table.execute DB
        lambda do
          @table.execute(DB)
        end.should raise_error
      end

      it "should NOT set @executed to 'true'" do
        lambda do
          @table.execute DB, :test  # wrong table name
        end.should raise_error
        @table.executed.should_not be_true
      end
    end
  end
end
