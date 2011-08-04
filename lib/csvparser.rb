require 'parslet'
require 'pp'

csv_abfn = <<EOS
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


# Parset rules accoding to the above abfn rules, except for that I don't distinguish between a header and a record. 
class CSVParser < Parslet::Parser
 
  rule(:comma) {str(',')}
  rule(:d_quote) {str('"')}
  rule(:textdata) {((comma | d_quote | str('\n') | str('\r')).absent? >> any).repeat(1)}
  rule(:non_escaped) {textdata.repeat}
  rule(:escaped) {d_quote >> (textdata | comma | d_quote >> d_quote | str('\n') | str('\r')).repeat >> d_quote}
  rule(:field) {escaped | non_escaped}
  rule(:newline) { str("\n") >> str("\r").maybe}
  rule(:record) {field.as(:column) >> (comma >> field.as(:column)).repeat}
  rule(:file) {record.as(:row) >> (newline >> record.as(:row)).repeat >> newline.maybe}
  root(:file)

end

# Example data taken from:
# http://www.creativyst.com/Doc/Articles/CSV/CSV01.htm
csv_content = <<CSV
John,Doe,120 jefferson st.,Riverside, NJ, 08075
Jack,McGinnis,220 hobo Av.,Phila, PA,09119
Stephen,Tyler,"7452 Terrace ""At the Plaza"" road",SomeTown,SD, 91234
"John ""Da Man""",Repici,120 Jefferson St.,Riverside, NJ,08075
,Blankman,,SomeTown, SD, 00298
"Joan ""the bone"", Anne",Jet,"9th, at Terrace plc",Desert City,CO,00123
CSV


pp CSVParser.new.parse(csv_content)

# `parse_failed': Don't know what to do with "John ""Da Man""",Repici,120 Jefferson St.,Riverside, NJ,08075 (Parslet::UnconsumedInput)
# ,Blankman,,SomeTown, SD, 00298
# "Joan  at line 4 char 1.

