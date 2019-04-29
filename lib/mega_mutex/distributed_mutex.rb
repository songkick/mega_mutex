require 'logging'
require 'redis'

module MegaMutex
  class TimeoutError < Exception; end

  class DistributedMutex
    class << self
      def cache
        @cache ||= Redis.new MegaMutex.configuration.redis_servers#, :namespace => MegaMutex.configuration.namespace
      end
    end

    def initialize(key, timeout = nil)
      @key = key
      @timeout = timeout
    end

    def logger
      Logging::Logger[self]
    end

    def run(&block)
      @start_time = Time.now
      log "Attempting to lock mutex..."
      lock!
      log "Locked. Running critical section..."
      result = yield
      log "Critical section complete. Unlocking..."
      result
    ensure
      unlock!
      log "Unlocking Mutex."
    end

    def current_lock
      cache.get(@key)
    end

  private

    def timeout?
      return false unless @timeout
      Time.now > @start_time + @timeout
    end

    def log(message)
      logger.debug do
        "(key:#{@key}) (lock_id:#{my_lock_id}) #{message}"
      end
    end

    def lock!
      until timeout?
        return if attempt_to_lock == my_lock_id
        sleep 0.1
      end
      raise TimeoutError.new("Failed to obtain a lock within #{@timeout} seconds.")
    end

    def attempt_to_lock
      if current_lock.nil?
        set_current_lock my_lock_id
      end
      current_lock
    end

    def unlock!
      cache.del(@key) if locked_by_me?
    end

    def locked_by_me?
      current_lock == my_lock_id
    end

    def set_current_lock(new_lock)
      cache.set(@key, my_lock_id)
    end

    def my_lock_id
      @my_lock_id ||= "#{Process.pid.to_s}.#{self.object_id.to_s}.#{Time.now.to_i.to_s}"
    end

    def cache
      self.class.cache
    end
  end
end
