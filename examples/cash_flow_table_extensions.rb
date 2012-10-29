module Yummi
  module Colorizers
    def self.blessed_income color
      Yummi::to_colorize do |ctx|
        color if ctx[:value] > ctx[:total]
      end
    end
  end
end
