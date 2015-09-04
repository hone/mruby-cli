module MRubyCLI
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
      value ? "#{name}:" : name
    end
  end
end
