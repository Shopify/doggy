module Doggy
  module Serializer
    class Json
      # De-serialize a Hash from JSON string
      def self.load(string)
        ::JSON.load(string)
      end

      # Serialize a Hash to JSON string
      def self.dump(object, options = {})
        ::JSON.pretty_generate(object, options) + "\n"
      end
    end
  end
end
