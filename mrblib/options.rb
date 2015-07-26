module MRubyCLI
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
