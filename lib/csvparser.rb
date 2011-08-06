# encoding: utf-8
# http://blog.grayproductions.net/articles/ruby_19s_three_default_encodings
require 'parslet'
require 'pp'
require 'parslet/convenience'

# Common Format and MIME Type for CSV Files (RFC 4180)
# Source: http://www.ietf.org/rfc/rfc4180.txt
csv_abnf = <<EOS
  file        = [header CRLF] record *(CRLF record) [CRLF]
  header      = name *(COMMA name)
  record      = field *(COMMA field)
  name        = field
  field       = (escaped / non-escaped)
  escaped     = DQUOTE *(TEXTDATA / COMMA / CR / LF / 2DQUOTE) DQUOTE
  non-escaped = *TEXTDATA
  COMMA       = %x2C
  CR          = %x0D 
  DQUOTE      = %x22
  LF          = %x0A
  CRLF        = CR LF
  TEXTDATA    = %x20-21 / %x23-2B / %x2D-7E
EOS


# Parset rules accoding to the above abnf rules, except for that I don't distinguish between a header and a record. 
class CSVParser < Parslet::Parser

  @delimiter = ','

  def initialize delimiter = ','
   @delimiter = delimiter 
  end
 
  rule(:file)        {(record.as(:row) >> newline).repeat(1)}
  # rule(:file)        {record.as(:row) >> (newline >> record.as(:row)).repeat >> newline.maybe}
  rule(:non_escaped) {textdata.repeat}
  rule(:record)      {field.as(:column) >> (comma >> field.as(:column)).repeat}
  rule(:field)       {escaped | non_escaped}
  rule(:escaped)     {d_quote >> (textdata | comma | cr | lf | d_quote >> d_quote).repeat >> d_quote}
  rule(:textdata)    {((comma | d_quote | cr | lf).absent? >> any).repeat(1)}
  rule(:newline)     {lf >> cr.maybe}
  rule(:lf)          {str("\n")}
  rule(:cr)          {str("\r")}
  rule(:d_quote)     {str('"')}
  rule(:comma)       {str(@delimiter)} 

  root(:file)
end

# Example data taken from:
# http://www.creativyst.com/Doc/Articles/CSV/CSV01.htm
csv_content = <<CSV
John,Doe,120 jefferson st.,Riverside,, 08075
Jack,McGinnis,220 hobo Av.,Phila, PA,09119
Stephen,Tyler,"7452 
Terrace ""At the Plaza"" road",SomeTown,SD, 91234
"John ""Da Man""",Repici,120 Jefferson St.,Riverside, NJ,08075
,Blankman,,SomeTown, SD, 00298
"Joan ""the bone"", Anne",Jet,"9th, at Terrace plc",Desert City,CO,00123
CSV

csv_content2 = <<CSV
"col1","col2","col3","col4","col5","col6"
1,2,3,4,5,6
10,20,,,,
CSV

# semicolon (;) as the delimiter
csv_content3 = <<CSV
"col1";"col2";"col3";"col4";"col5";"col6"
1;2;3;4;5;6
10;20;;;;
CSV
# pp CSVParser.new.parse_with_debug(csv_content)
# pp CSVParser.new.parse(csv_content2)

pp CSVParser.new(';').parse(csv_content3)

csv_content_chinese = <<CSV
"编码","规格","单价（美元）","数量","总价（美元）"
1,"好产品",3,2,6
2,"豪华汽车，价格很划算",,,
3,"“小兔”牌",4.4,10,44
CSV

pp CSVParser.new.parse(csv_content_chinese)


