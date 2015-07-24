module MrubyCli
  class CLI
    def initialize(argv, output_io = $stdout, error_io = $stderr)
      @options = setup_options
      @opts = @options.parse(argv)
      @output_io = output_io
      @error_io  = error_io
    end

    def run
      if app_name = @options.option(:setup)
        Setup.new(app_name, @output_io).run
      elsif @options.option(:version)
        Version.new(@output_io).run
      else
        Help.new(@output_io).run
      end
    end

    private
    def setup_options
      options = Options.new
      options.add(Option.new("setup", "s", true))
      options.add(Option.new("version", "v"))
      options.add(Option.new("help", "h"))

      options
    end
  end
end
