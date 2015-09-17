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
  end
end
