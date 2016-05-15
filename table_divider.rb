class TableDivider
  attr_accessor :html_table
  attr_accessor :divided_tables

  def initialize(html_table)
    @table = html_table
    @max_table_rows = 9
    @divided_tables = []
  end

  def wrap_rows rows
    "<table>#{rows}</table>"
  end

  def divide html_fragment
    table_rows = html_fragment.css('tr')
    if table_rows.count > @max_table_rows
      table_rows.each_slice(@max_table_rows) do |rows_set|
        @divided_tables << wrap_rows(rows_set.map{ |rows| rows.to_html }.join())
      end
      @divided_tables
    end
  end

  def perform!
    divide(@table)
  end

end

