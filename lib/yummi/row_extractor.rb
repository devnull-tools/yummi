module Yummi
  module RowExtractor

    def extract_row_from_hash(row, row_index)
      array = []
      @aliases.each_index do |column_index|
        key = @aliases[column_index]
        obj = TableContext::new(
          :obj => row,
          :row_index => row_index,
          :column_index => column_index,
          :value => (row[key.to_sym] or row[key.to_s])
        )
        array << obj
      end
      array
    end

    def extract_row_from_range(row, row_index)
      row.to_a
    end

    def extract_row_from_array(row, row_index)
      array = []
      row.each_index do |column_index|
        obj = TableContext::new(
          :obj => IndexedData::new(@aliases, row),
          :row_index => row_index,
          :column_index => column_index,
          :value => row[column_index]
        )
        array << obj
      end
      array
    end

    def extract_row_from_object(row, row_index)
      array = []
      @aliases.each_index do |column_index|
        obj = TableContext::new(
          :obj => row,
          :row_index => row_index,
          :column_index => column_index,
          :value => row.send(@aliases[column_index])
        )
        def obj.[] (index)
          obj.send(index)
        end
        array << obj
      end
      array
    end

  end
end