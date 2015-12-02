module MRubyCLI
  class CLI
    def initialize(argv, output_io = $stdout, error_io = $stderr)
      @usage = setup_options
      @options = Docopt.parse(@usage, argv)
      @output_io = output_io
      @error_io  = error_io
    end

    def run
      if @options["setup"]
        Setup.new(@options["<name>"], @output_io).run
      elsif @options["--version"]
        Version.new(@output_io).run
      else
        Help.new(@usage, @output_io).run
      end
    end

    private
    def setup_options
      USAGE = <<USAGE
mruby-cli.

  Usage:
    mruby-cli setup <name>
    mruby-cli (-v | --version)
    mruby-cli (-h | --help)

Create your own cli application.
Setup will scafold your application.

  Arguments:
    name              The name of your application

  Options:
    -h --Help         Show this screen.
    -v --version      Show version.
USAGE
    end
  end
end
