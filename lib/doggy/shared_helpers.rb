module Doggy
  module SharedHelpers
    MAX_TRIES = 5

    def self.strip_heredoc(string)
      indent = string.scan(/^[ \t]*(?=\S)/).min.try(:size) || 0
      string.gsub(/^[ \t]{#{indent}}/, '')
    end

    def self.with_retry(times: MAX_TRIES, reraise: false)
      tries = 0
      while tries < times
        begin
          yield
          break
        rescue => e
          error "Caught error! Attempt #{tries}..."
          error "#{e.class.name}: #{e.message}"
          error "#{e.backtrace.join("\n")}"
          tries += 1

          raise e if tries >= times && reraise
        end
      end
    end

    def self.agree(prompt)
      raise Error, "Not a tty" unless $stdin.tty?

      puts prompt + " (Y/N)"
      line = $stdin.readline.chomp.upcase
      puts
      line == "Y"
    end

    def self.find_root
      File.dirname(find_file("Gemfile"))
    end

    def self.find_file(*names)
      search_up(*names) do |filename|
        return filename if File.file?(filename)
      end
    end

    def self.search_up(*names)
      previous = nil
      current  = File.expand_path(Pathname.pwd)

      until !File.directory?(current) || current == previous
        names.each do |name|
          filename = File.join(current, name)
          yield filename
        end
        current, previous = File.expand_path("..", current), current
      end
    end
  end
end
