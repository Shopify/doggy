require 'cgi'
require 'thor'
require 'doggy'

module Doggy
  def self.with_friendly_errors
    yield
  rescue Doggy::Dsl::DSLError => e
    puts e.message
    exit e.status_code
  rescue Doggy::DoggyError => e
    puts e.message
    puts e
    exit e.status_code
  rescue Thor::AmbiguousTaskError => e
    puts e.message
    exit 15
  rescue Thor::UndefinedTaskError => e
    puts e.message
    exit 15
  rescue Thor::Error => e
    puts e.message
    exit 1
  rescue Interrupt => e
    puts "\nQuitting..."
    puts e
    exit 1
  rescue SystemExit => e
    exit e.status
  rescue Exception => e
    request_issue_report_for(e)
    exit 1
  end

  def self.request_issue_report_for(e)
    puts <<-EOS.gsub(/^ {6}/, "")
      --- ERROR REPORT TEMPLATE -------------------------------------------------------
      - What did you do?

        I ran the command `#{$PROGRAM_NAME} #{ARGV.join(" ")}`

      - What did you expect to happen?

        I expected Doggy to...

      - What happened instead?

        Instead, what actually happened was...


      Error details

          #{e.class}: #{e.message}
            #{e.backtrace.join("\n            ")}

      --- TEMPLATE END ----------------------------------------------------------------

    EOS

    puts "Unfortunately, an unexpected error occurred, and Doggy cannot continue."

    puts <<-EOS.gsub(/^ {6}/, "")

      First, try this link to see if there are any existing issue reports for this error:
      #{issues_url(e)}

      If there aren't any reports for this error yet, please create copy and paste the report template above into a new issue. Don't forget to anonymize any private data! The new issue form is located at:
      https://github.com/bai/doggy/issues/new
    EOS
  end

  def self.issues_url(exception)
    "https://github.com/bai/doggy/search?q=" \
    "#{CGI.escape(exception.message.lines.first.chomp)}&type=Issues"
  end
end
