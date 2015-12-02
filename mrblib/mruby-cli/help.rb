module MRubyCLI
  class Help
    def initialize(usage, output_io)
      @usage = usage
      @output_io = output_io
    end

    def run
      @output_io.puts @usage
    end
  end
end
