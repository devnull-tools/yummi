require_relative '../lib/yummi'

table = Yummi::Table::new
table.header = ['Description', 'Value', 'Total', 'Eletronic']
table.title = 'Test Table'
table.align :description, :left
table.colorize :description, :with => :purple
colorizer = Yummi::Colorizer.case(
  [:<, 0, :with => :red],
  [:>, 0, :with => :green],
  [:==, 0, :with => :brown]
)
table.colorize :eletronic, :using => Yummi::Colorizer.case(
  [:==, true, :with => :green],
  [:==, false, :with => :red]
)
table.colorize :value, :using => colorizer
table.colorize :total, :using => colorizer
table.row_colorizer Yummi::RowColorizer.if(:value, :>, :total, :with => :white)

table.format :eletronic, :using => Yummi::Formatter.yes_or_no
table.format :value, :with => "%.2f"
table.format :total, :with => "%.2f"

table.data = [['Initial', 0, 0, false],
              ['Deposit', 100, 100, true],
              ['Withdraw', -50, 50, false],
              ['Withdraw', -100, -50, true],
              ['Deposit', 50, 0, false],
              ['Deposit', 600, 600, true]]

table.print
