require 'rubygems'
$:.push File.expand_path(File.dirname(__FILE__)) unless $:.include?(File.expand_path(File.dirname(__FILE__)))
require 'mega_mutex/distributed_mutex'

# == Why
#
# Sometimes I need to do this:
#
#     unless enough_things?
#       make_more_things
#     end
#
# If I'm running several processes in parallel, I can get a race condition that means two of the processes both think there are not enough things. So we go and make some more, even though we don't need to.
#
# == How
#
# Suppose you have a ThingMaker:
#
#     class ThingMaker
#       include MegaMutex
#
#       def ensure_just_enough_things
#         with_cross_process_mutex("ThingMaker Mutex ID") do
#           unless enough_things?
#             make_more_things
#           end
#         end
#       end
#     end
#
# Now, thanks to the magic of MegaMutex, you can be sure that all processes trying to run this code will wait their turn, so each one will have the chance to make exactly the right number of things, without anyone else poking their nose in.
#
# == Configuration
#
# MegaMutex Redis to store the mutex, so your infrastructure must be set up to use redis servers.
#
# By default, MegaMutex will attempt to connect to a redis server on the local machine, but you can configure any number of servers like so:
#
#     MegaMutex.configure do |config|
#       config.redis_servers = {:host => 'xxx', :port => 6379}
#     end
module MegaMutex

  def self.get_current_lock(mutex_id)
    DistributedMutex.new(mutex_id).current_lock
  end

  ##
  # Wraps code that should only be run when the mutex has been obtained.
  #
  # The mutex_id uniquely identifies the section of code being run.
  #
  # You can optionally specify a :timeout to control how long to wait for the lock to be released
  # before raising a MegaMutex::TimeoutError
  #
  #   with_distributed_mutex('my_mutex_id_1234', :timeout => 20) do
  #     do_something!
  #   end
  def with_distributed_mutex(mutex_id, options = {}, &block)
    mutex = DistributedMutex.new(mutex_id, options[:timeout])
    begin
      mutex.run(&block)
    rescue Object => e
      mega_mutex_insert_into_backtrace(
        e,
        /mega_mutex\.rb.*with_(distributed|cross_process)_mutex/,
        "MegaMutex lock #{mutex_id}"
      )
      raise e
    end
  end
  alias :with_cross_process_mutex :with_distributed_mutex

  # inserts a line into a backtrace at the correct location
  def mega_mutex_insert_into_backtrace(exception, re, newline)
    loc = nil
    exception.backtrace.each_with_index do |line, index|
      if line =~ re
        loc = index
        break
      end
    end
    if loc
      exception.backtrace.insert(loc, newline)
    end
  end

  class Configuration
    attr_accessor :redis_servers, :namespace

    def initialize
      @redis_servers = {:host => 'redis.dev', :port => 6379}
      @namespace = 'mega_mutex'
    end
  end

  class << self
    def configure
      yield configuration
    end

    def configuration
      @configuration ||= Configuration.new
    end
  end
end

