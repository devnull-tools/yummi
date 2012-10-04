module Yummi
  module Colorizers
    def self.blessed_income color
      Yummi::to_colorize do |data| # or |data, index| if you need the index
        color if data[:value] > data[:total]
      end
    end
  end
end
