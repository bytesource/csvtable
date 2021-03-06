# Usage:
# sovonex@sovonex:~/Desktop/temp/csv/test$ rspec csvtable_spec.rb

require File.expand_path('../lib/csvtable')

describe CSVTable do

  before(:each) do
    @file = "DNA@check.csv"
    @path_to = File.join(File.expand_path('tables'), '/')
    @path = @path_to + @file
    # Item,Description,Price
    # 1,"This is a great product"
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
      end.should raise_error(Exception, "Can only read csv files")
    end

    # it "should raise an exception if one or more headers are missing" do
    #   # Not sure how to implement this feature.
    #   @missing_header = "DNA@missing_a_header.csv"
    #   @path = @path_to + @missing_header
    #   lambda do
    #     CSVTable.new(@path)
    #   end.should raise_error(Exception, "At least one header is missing")
    # end
  end


  describe "instance variables" do

    it "should have the right name" do
      @table.name.should == :dna
    end


    it "should raise an exception if the separator is given without a prefix (or only contains whitespace)" do
      @separator_without_prefix = "  @check.csv"
      @path = @path_to + @separator_without_prefix
      lambda do
        CSVTable.new(@path)
      end.should raise_error(Exception, "No table name given!")
    end


    it "should use the file name as the table name if the separator is not given" do
      @no_separator = "NoSeparator.csv"
      @path = @path_to + @no_separator
        table = CSVTable.new(@path)

      table.name.should == :noseparator
    end


    it "it should convert whitespace and hyphens into underscore before setting @name" do
      @space_hyphens = "I have Space - - and hyphens.csv"
      @path = @path_to + @space_hyphens
      table = CSVTable.new(@path)

      table.name.should == :i_have_space_and_hyphens
    end


    it "should set @executed to 'false'" do
      @table.executed.should == false
    end


    it "should set @data_hash to the correct hash value" do

      data = @table.fields.to_s

      test_hash = Digest::SHA2.hexdigest(data)

      @table.send(:make_hash, data).should == test_hash
    end


    it "should handle whitespace in headers and data columns" do
      # "      Item","    Description    ","           Price            "
      # 1,This is a great product
      # ,"This product is not so good        ",23.4
      # 3,,34.1
      # 4,"          alles komplett    ",23
      @file = "DNA@check_a_lot_of_whitespace.csv"
      @path = @path_to + @file
      table = CSVTable.new(@path)

      table.headers.should   == [:item, :description, :price] 
      table.fields[1].should == [nil, "This product is not so good", 23.4] 
    end


    it "should convert whitespaces and hyphens in a header to an underscore" do
      # Item  -- NO,Main  Description,Price -Range
      @file = "DNA@check_with_multi_word_header.csv"
      @path = @path_to + @file
      table = CSVTable.new(@path)

      table.headers.should == [:item_no, :main_description, :price_range]
    end


    it "should verify that the delimiter recognized by CSVTable and the delimiter of the csv file match" do
      lambda do
        table = CSVTable.new(@path, :delimiter => ";")
      end.should raise_error(Exception, "Delimiter ';' not found in header row.")
    end


    it "should handle data fields containing a delimiter correctly, 
        if the delimiter does have at least one whitespace before or after it" do
      # Item,Description,Price
      # 1,"This, is ,a great , product"
      # ...
      @file = "DNA@with_allowed_whitespace_in_data.csv"
      @path = @path_to + @file
      lambda do
        table = CSVTable.new(@path)
        table.fields[0].should == [1, "This, is ,a great , product", nil]
      end.should_not raise_error
        end


    # it "should handle numbers containing comma separators correctly" do
    #   # "34,456","34,000",345,34.45
    #   @file = "MATH@with_comma_in_number.csv"
    #   @path = @path_to + @file
    #   table = CSVTable.new(@path)

    #   table.fields.should == nil
    #   
    #   # table.fields[0].should == [34456, 34000, 345, 34.45]
    # end
  end


  describe "instance methods" do
    it "'replace_if_blank' should return the right value" do
      # http://stackoverflow.com/questions/4271696/rspec-rails-how-to-test-private-methods-of-controllers
      # Use send(:private_method) to call private method:
      @table.send(:replace_if_blank, "    ").should == nil
    end


    it "'prepare' should return the correct value" do
      result = @table.send(:prepare, File.open(@path))

      result[0].should == ["Item", "Description", "Price"]
      result[1].should == ["1", "This is a great product"]
      result[2].should == ["", "This product is not so good", "23.4"]
      result[3].should == ["3", "", "34.1"]
      result[4].should == ["4", "alles komplett", "23"]
    end


    it "'fields_headers_hash' should convert an array of arrays into an array of hashes" do

      array     = @table.fields[0] 
      result    = @table.send(:fields_headers_hash) {|row| row.merge(:hash => @table.data_hash)}

      hash      = {:hash => @table.data_hash}
      zip_array = @table.headers.zip(array)
      with_hash = Hash[*zip_array.flatten].merge(hash)

      result[0].should == with_hash
    end


    it "'str_to_num' should convert a string representing a number into its corresponding int or float, 
        and leave it untouched otherwise" do
      @table.send(:str_to_num, "no_number").should == "no_number"
      @table.send(:str_to_num, "23").should == 23
      @table.send(:str_to_num, "23000").should == 23000
      @table.send(:str_to_num, "23000.234").should == 23000.234
      @table.send(:str_to_num, "-23000.234").should == -23000.234
        end
  end


  describe "insert data into database: " do
    before(:each) do

      # Using before(:all) instead of before(:each), to avoid repeated initialization of 'DB'
      # @table from above is not recognized anymore. Therefore I had to create another CSVTable object:
      # @file = "DNA@check.csv"
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


      it "should also handle headers enclosed in quotes" do
        @file = "DNA@headers_with_quotes.csv"
        @path = @path_to = @file
        lambda do
          @table.execute DB
          @table.executed?.should be_true
        end.should_not raise_error
      end


      it "should work with a custom delimiter" do
        @file = "DNA@check_semicolon_delimiter.csv"
        @path = @path_to + @file
        my_table = CSVTable.new(@path, :delimiter => ';')
        lambda do
          my_table.execute DB
          my_table.executed?.should be_true
        end.should_not raise_error
      end


      it "should handle data fields containing a delimiter correctly, 
        if the delimiter does have at least one whitespace before or after it" do
        # Item,Description,Price
        # 1,"This, is ,a great , product"
        # ...
        @file = "DNA@with_allowed_whitespace_in_data.csv"
        @path = @path_to + @file
        table = CSVTable.new(@path)

        table.fields[0].should == [1, "This, is ,a great , product", nil]
        lambda do
          table.execute DB
          table.executed?.should be_true
        end.should_not raise_error
        end


      it "should throw an exception if there is a delimiter in a data field not surrounded by any whitespace" do
        # Item,Description,Price
        # 1,"This,is a great,product"
        # ...
        @file = "DNA@with_forbidden_whitespace_in_data.csv"
        @path = @path_to + @file

        lambda do
          table = CSVTable.new(@path)
        end.should raise_error(Exception, "Header and data field mismatch. Check for forbidden delimiters in data fields.")
        # NOTE: If the last data field of a row is empty (that means one delimiter missing) and a single forbidden delimiter
        # found in one of the data fields of the same row, no exception will be thrown, as there will be no mismatch in the 
        # size of the header and data row.
      end


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
        @exact_copy = "DNA@exact_copy.csv"
        @new_path   = @path_to + @file
        @table2 = CSVTable.new(@new_path)
        lambda do
          @table2.execute(DB)
          DB[@table.name].count.should == 4
        end.should raise_error(Exception, "Data already in table. Abort!")
      end
    end

    describe "on failure: " do

    end
  end
end
