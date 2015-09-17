module Doggy
  class DoggyError < StandardError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class ObjectFileError < DoggyError; status_code(12); end
  class ObjectFileEvalError < DoggyError; status_code(11); end
  class InvalidOption < DoggyError; status_code(15); end
  class InvalidItemType < DoggyError; status_code(10); end
end
