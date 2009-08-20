require File.expand_path(File.dirname(__FILE__) + '/../lib/mega_mutex')
require 'test/unit/assertions'

# Logging::Logger[:root].add_appenders(Logging::Appenders.stdout)

module ThreadHelper
  def abort_on_thread_exceptions
    before(:all) do
      @old_abort_on_exception_value = Thread.abort_on_exception
      Thread.abort_on_exception = true
    end
    after(:all) do
      Thread.abort_on_exception = @old_abort_on_exception_value
    end
  end
end

module ThreadExampleHelper
  def threads
    @threads ||= []
  end
  
  def wait_for_threads_to_finish
    threads.each{ |t| t.join }
  end
end

Spec::Runner.configure do |config|
  config.extend ThreadHelper
  config.include ThreadExampleHelper
  config.include Test::Unit::Assertions
end
