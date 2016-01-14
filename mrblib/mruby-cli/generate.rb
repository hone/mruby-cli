module MRubyCLI
  class Generate
    OBJECT_GENERATOR = [
      :cli,
      :help,
      :options,
      :version
    ]

    def initialize(name, output)
      @name   = name
      @output = output
    end

    def run(object)
      raise RuntimeError unless OBJECT_GENERATOR.include? object
      send("generate_#{object}")
    end

    private
    def generate_help
      Util::write_file("mrblib/#{@name}/help.rb", content_of_help_rb)
    end

    def content_of_help_rb
      <<HELP_RB
module #{Util::camelize(@name)}
  class Help
    def initialize(output_io)
      @output_io = output_io
    end

    def run
      @output_io.puts "#{@name} [switches] [arguments]"
      @output_io.puts "#{@name} -h, --help               : show this message"
      @output_io.puts "#{@name} -v, --version            : print #{@name} version"
    end
  end
end
HELP_RB
    end

    def generate_cli
      Util::write_file("mrblib/#{@name}/cli.rb", content_of_cli_rb)
    end

    def content_of_cli_rb
      <<CLI_RB
module #{Util::camelize(@name)}
  class CLI
    def initialize(argv, output_io = $stdout, error_io = $stderr)
      @options = setup_options
      @opts = @options.parse(argv)
      @output_io = output_io
      @error_io  = error_io
    end

    def run
      if @options.option(:version)
        Version.new(@output_io).run
      elsif @options.option(:help)
        Help.new(@output_io).run
      else
        @output_io.puts "Hello World"
      end
    end

    private
    def setup_options
      options = Options.new
      options.add(Option.new("version", "v"))
      options.add(Option.new("help", "h"))

      options
    end
  end
end
CLI_RB
    end

    def generate_version
      Util::write_file("mrblib/#{@name}/version.rb", content_of_version_rb)
    end

    def content_of_version_rb
      <<VERSION_RB
module #{Util::camelize(@name)}
  class Version
    VERSION = "0.0.1"

    def initialize(output_io)
      @output_io = output_io
    end

    def run
      @output_io.puts "#{@name} version \#{VERSION}"
    end
  end
end
VERSION_RB
    end

    def generate_options
      Util::write_file("mrblib/#{@name}/option.rb", content_of_option_rb)
      Util::write_file("mrblib/#{@name}/options.rb", content_of_options_rb)
    end

    def content_of_option_rb
      <<OPTION_RB
module #{Util::camelize(@name)}
  class Option
    attr_reader :short, :long, :value

    def initialize(long, short, value = false)
      @short = short
      @long  = long
      @value = value
    end

    def to_long_opt
      to_getopt(@long, @value)
    end

    def to_short_opt
      to_getopt(@short, @value)
    end

    private
    def to_getopt(name, value)
      value ? "\#{name}:" : name
    end
  end
end
OPTION_RB
    end

    def content_of_options_rb
      <<OPTIONS_RB
module #{Util::camelize(@name)}
  class Options
    attr_reader :short_opts, :long_opts
    attr_writer :parsed_opts

    def initialize
      @options           = {}
      @short_opts_array  = []
      @short_opts        = ""
      @long_opts         = []
      @parsed_opts       = {}
    end

    def add(option)
      @options[option.long.to_sym] = option
      @long_opts << option.to_long_opt
      @long_opts.sort!
      @short_opts_array << option.to_short_opt
      @short_opts = @short_opts_array.sort!.join("")

      option
    end

    def parse(args)
      class << args; include Getopts; end
      @parsed_opts = args.getopts(@short_opts, *@long_opts)
    end

    def option(long_opt)
      option = @options[long_opt]

      return nil unless option
      if retn = @parsed_opts[option.long]
        if option.value
          return retn unless retn.empty?
        else
          return retn
        end
      end
      return @parsed_opts[option.short] if @parsed_opts[option.short]
      return false
    end
  end
end
OPTIONS_RB
    end

  end
end
