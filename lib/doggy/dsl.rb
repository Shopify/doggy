module Doggy
  class Dsl
    def self.evaluate(object_file)
      builder = new
      builder.eval_file(object_file)
      builder.to_definition
    end

    def initialize
      @obj = {}
    end

    def eval_file(object_file, contents = nil)
      contents ||= File.open(object_file.to_s, "rb") { |f| f.read }
      instance_eval(contents, object_file.to_s, 1)
    rescue Exception => e
      message = "There was an error " \
        "#{e.is_a?(ObjectFileEvalError) ? "evaluating" : "parsing"} " \
        "`#{File.basename object_file.to_s}`: #{e.message}"

      raise DSLError.new(message, object_file, e.backtrace, contents)
    end

    def obj(structure)
      @obj = structure
    end

    # @return [Definition] the parsed object definition.
    def to_definition
      Definition.new(@obj)
    end

    def method_missing(name, *args)
      raise Doggy::ObjectFileError, "Undefined local variable or method `#{name}' for object file"
    end

    private

    class DSLError < Doggy::ObjectFileError
      # @return [String] the message that should be presented to the user.
      attr_reader :message

      # @return [String] the path of the dsl file that raised the exception.
      attr_reader :dsl_path

      # @return [Exception] the backtrace of the exception raised by the evaluation of the dsl file.
      attr_reader :backtrace

      # @param [Exception] backtrace @see backtrace
      # @param [String]    dsl_path  @see dsl_path
      def initialize(message, dsl_path, backtrace, contents = nil)
        @status_code = $!.respond_to?(:status_code) && $!.status_code

        @message = message
        @dsl_path    = dsl_path
        @backtrace   = backtrace
        @contents    = contents
      end

      def status_code
        @status_code || super
      end

      # @return [String] the contents of the DSL that cause the exception to
      #         be raised.
      def contents
        @contents ||= begin
          dsl_path && File.exist?(dsl_path) && File.read(dsl_path)
        end
      end
    end
  end
end
