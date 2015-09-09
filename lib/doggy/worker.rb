require 'thread'
require 'thread/pool'

Thread.abort_on_exception = true

module Doggy
  class Worker
    # Spawn 10 threads for HTTP requests.
    CONCURRENT_STREAMS = 10

    def initialize(options = {}, &runner)
      @runner = runner
      @threads = options.fetch(:threads)
    end

    def call(jobs)
      results = []
      pool = Thread::Pool.new(@threads)
      tasks = jobs.map { |job|
        pool.process {
          results << [ job, @runner.call(job) ]
        }
      }
      pool.shutdown
      if task_with_errors = tasks.detect { |task| task.exception }
        raise task_with_errors.exception
      end
      results
    end
  end
end
