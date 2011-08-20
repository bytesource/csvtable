require '../lib/csvtable' 
require '../lib/dbtable'

describe "DBTable" do

  describe "On initialization" do

    it "should add 'CodonsTable' to the @table_classes class instance variable" do

      DBTable.table_classes.should  == {:codons=>CodonsTable}
    end
  end

  describe "Connection" do

    before(:each) do
      @dbtable = DBTable.new 
    end

    it "connecting to the database should not throw an error" do

      lambda do
        @dbtable.connect
      end.should_not raise_error
    end
  end

  describe "Subclasses" do

    before(:each) do
      @dbtable = DBTable.new
    end

    it "should return the correct name" do

      CodonsTable.name.should == :codons
    end

    it "should create a database table" do


      codons = CodonsTable.new
      codons.create_table
      lambda do
        codons.create_table
      end.should_not raise_error
    end
  end
end
