module MrubyCli
  class CLI
    def initialize(argv, output_io = $stdout, error_io = $stderr)
      class << argv; include Getopts; end
      @opts = argv.getopts(short_opts, *long_opts)
    end

    def run
      if app_name = (@opts["s"] || @opts["setup"])
        Setup.new(app_name).run
      elsif @opts["h"] || @opts["help"]
        help
      end
    end

    private
    def short_opts
      "s:h"
    end

    def long_opts
      %w(setup: help)
    end
    
    def help
    end
  end
end
