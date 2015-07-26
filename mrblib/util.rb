module MrubyCli
  class Util
    class << self
      def camelize(string)
        string.split("-").map {|w| w.capitalize }.map {|w|
          w.split("_").map {|w2| w2.capitalize }.join('')
        }.join('')
      end
    end
  end
end
