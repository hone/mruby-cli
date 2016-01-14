module MRubyCLI
  class Util
    class << self
      def camelize(string)
        string.split("-").map {|w| w.capitalize }.map {|w|
          w.split("_").map {|w2| w2.capitalize }.join('')
        }.join('')
      end

      def create_dir_p(dir)
        dir.split("/").inject("") do |parent, base|
          new_dir =
            if parent == ""
              base
            else
              "#{parent}/#{base}"
            end

          create_dir(new_dir)

          new_dir
        end
      end

      def create_dir(dir)
        if Dir.exist?(dir)
          @output.puts "  skip    #{dir}"
        else
          @output.puts "  create  #{dir}/"
          Dir.mkdir(dir)
        end
      end

      def write_file(file, contents)
        @output.puts "  create  #{file}"
        File.open(file, 'w') {|file| file.puts contents }
      end
    end
  end
end
