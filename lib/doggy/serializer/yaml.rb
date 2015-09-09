module Doggy
  module Serializer
    class Yaml
      # De-serialize a Hash from YAML string
      def self.load(string)
        ::YAML.load(string)
      end

      # Serialize a Hash to YAML string
      def self.dump(object, options = {})
        ::YAML.dump(object, options)
      end
    end
  end
end
