require "celluloid"
require "awesome_print"
require "securerandom"
require "set"

class Worker
  include Celluloid
  include Celluloid::Logger

  attr_accessor :name

  def initialize(options = {})
    self.name = options[:name]
  end

  def add_one(n)
    return (n * 2)
  end

  def files
    return (0..100).to_a
  end

end

class AWorker < Worker
end

class MyWorker < Worker
end


class Client < Celluloid::SupervisionGroup
  include Celluloid
  include Celluloid::Logger
  finalizer :sync_complete

  attr_accessor :incomplete_jobs, :complete_jobs, :sources

  attr_accessor :sync_attempts, :file_sync_attempts

  attr_accessor :started_at, :finished_at

  def initialize(registry = nil)
    self.incomplete_jobs = Set.new
    self.complete_jobs = Set.new
    self.sources = []
    self.sync_attempts = 0
    self.file_sync_attempts = 0
    super(registry)
  end

  #
  def add_target(options={})
    self.pool(options[:class], :as => options[:as], :args => [options[:args]])
  end

  #
  def add_source(options={})
    self.sources << { :id => SecureRandom.uuid, :targets => options[:targets]}
  end

  #
  def start_sync

    determine_sync if first_run?
    sync_attempted
    
    self.incomplete_jobs.delete_if do | job |
      begin
        completed_job = { :id => job[:id], :response => Celluloid::Actor[job[:target_id]].future.send(job[:method], job[:args]).value }
      rescue
        self.file_sync_attempts = self.file_sync_attempts + 1
        false
      else
        self.complete_jobs << completed_job
        true
      end
    end

    finish_sync

  end

  #
  def sync_complete

    if self.finished_at
      info "Sync completed in #{(self.finished_at - self.started_at).to_i} seconds"
      info "#{self.complete_jobs.length} file(s) have been synchronised from #{self.sources.length} source(s) to #{self.actors.length} target(s)"
      info "#{self.file_sync_attempts} failed request(s) were detected and re-tried"
    else
      info "Sync failed to complete with #{self.incomplete_jobs.length} outstanding file(s) to be synchronised"
      info "#{self.complete_jobs.length} file(s) were synchronised from #{self.sources.length} source(s) to #{self.actors.length} target(s)"
    end
    
  end


  private

  #
  def determine_sync
    self.sources.each do |source|
      source[:targets].each do | target_id |
        Celluloid::Actor[target_id].files.each { |n|
          self.incomplete_jobs << { :id => SecureRandom.uuid, :target_id => target_id, :source => source[:id], :method => :add_one, :args => n } 
        }
      end
    end
  end

  def sync_attempted
    self.started_at = Time.now if first_run?
    self.sync_attempts = self.sync_attempts + 1
    raise ArgumentError if self.sync_attempts > 10
  end

  def finish_sync
    (self.incomplete_jobs.length != 0) ? self.start_sync : self.finished_at = Time.now
  end

  def first_run?
    self.sync_attempts == 0
  end

end

client = Client.run!
client.add_target(:class => AWorker, :as => :a_worker, :args => { :name => "foo" })
client.add_target(:class => MyWorker, :as => :my_worker, :args => { :name => "bar" })
client.add_source(:targets => [:a_worker, :my_worker])
client.start_sync