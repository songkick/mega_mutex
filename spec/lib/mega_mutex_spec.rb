require File.expand_path(File.dirname(__FILE__) + '/../../lib/mega_mutex')

# Logging::Logger[:root].add_appenders(Logging::Appenders.stdout)

module MegaMutex
  describe MegaMutex do
    def logger
      Logging::Logger['Specs']
    end

    before(:all) do
      @old_abort_on_exception_value = Thread.abort_on_exception
      Thread.abort_on_exception = true
    end
    after(:all) do
      Thread.abort_on_exception = @old_abort_on_exception_value
    end

    describe "two blocks, one fast, one slow" do
      before(:each) do
        @errors = []
        @mutually_exclusive_block = lambda do
          @errors << "Someone else is running this code!" if @running
          @running = true
          sleep 0.5
          @running = nil
        end
      end

      describe "with no lock" do
        it "trying to run the block twice should raise an error" do
          threads = []
          threads << Thread.new(&@mutually_exclusive_block)
          threads << Thread.new(&@mutually_exclusive_block)
          threads.each{ |t| t.join }
          @errors.should_not be_empty
        end
      end

      describe "with the same lock key" do
        before(:each) do
          MemCache.new('localhost').delete(mutex_id)
        end

        def mutex_id
          'tests-mutex-key'
        end

        include MegaMutex

        [2, 20].each do |n|
          describe "when #{n} blocks try to run at the same instant in the same process" do
            it "should run each in turn" do
              threads = []
              n.times do
                threads << Thread.new{ with_cross_process_mutex(mutex_id, &@mutually_exclusive_block) }
              end
              threads.each{ |t| t.join }
              @errors.should be_empty
            end
          end
        end

        describe "when the first block raises an exception" do
          before(:each) do
            with_cross_process_mutex(mutex_id) do
              raise "Something went wrong in my code"
            end rescue nil
          end

          it "the second block should find that the lock is clear and it can run" do
            @success = nil
            with_cross_process_mutex(mutex_id) do
              @success = true
            end
            @success.should be_true
          end
        end

        describe "when two blocks try to run at the same instant in different processes" do
          before(:each) do
            @lock_file   = File.expand_path(File.dirname(__FILE__) + '/tmp_lock')
            @errors_file = File.expand_path(File.dirname(__FILE__) + '/tmp_errors')
            @mutually_exclusive_block = lambda {
              File.open(@errors_file, 'w').puts "Someone else is running this code!" if File.exists?(@lock_file)
              FileUtils.touch @lock_file
              sleep 1
              File.delete @lock_file
            }
          end

          after(:each) do
            File.delete @lock_file   if File.exists?(@lock_file)
            File.delete @errors_file if File.exists?(@errors_file)
          end

          it "should run each in turn" do
            pids = []
            pids << fork { with_cross_process_mutex(mutex_id, &@mutually_exclusive_block); Kernel.exit! }
            pids << fork { with_cross_process_mutex(mutex_id, &@mutually_exclusive_block); Kernel.exit! }
            pids.each{ |p| Process.wait(p) }
            if File.exists?(@errors_file)
              raise "Expected no errors but found #{File.read(@errors_file)}"
            end
          end
        end

      end
    end
  
    describe "with a timeout" do
      include MegaMutex
      it "should raise an error if the code blocks for longer than the timeout" do
        # TODO: this fails sometimes, and I presume it's when the second thread doesn't start quickly enough
        # meaning the first mutex has finished, and the timeout doesn't happen.
        @success = false
        threads = []
        threads << Thread.new{ with_cross_process_mutex('foo'){ sleep 2 } }
        threads << Thread.new do
          begin
            with_cross_process_mutex('foo', :timeout => 1 ){ puts 'nobody will ever hear me scream' } 
          rescue MegaMutex::TimeoutError
            @success = true
          end
        end
        threads.each{ |t| t.join }
        @success.should be_true
      end
    end
  end
end