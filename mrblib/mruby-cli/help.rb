module MRubyCLI
  class Help
    def initialize(output_io)
      @output_io = output_io
    end

    def run
      @output_io.puts "mruby-cli [switches] [arguments]"
      @output_io.puts "mruby-cli -h, --help               : show this message"
      @output_io.puts "mruby-cli -s<name>, --setup=<name> : setup your app"
      @output_io.puts "mruby-cli -v, --version            : print mruby-cli version"
    end
  end
end
