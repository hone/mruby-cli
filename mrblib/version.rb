module MrubyCli
  class Version
    VERSION = "0.0.1"

    def initialize(output_io)
      @output_io = output_io
    end

    def run
      @output_io.puts "mruby-cli version #{VERSION}"
    end
  end
end
