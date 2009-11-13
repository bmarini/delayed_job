require 'rubygems'
require 'benchmark'
require 'active_record'
gem 'sqlite3-ruby'
require File.dirname(__FILE__) + '/../init'
  
ActiveRecord::Base.logger = Logger.new('/tmp/dj.log')
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => '/tmp/jobs.sqlite')
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.default_timezone = :utc if Time.zone.nil?

ActiveRecord::Schema.define do
  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority, :default => 0
    table.integer  :attempts, :default => 0
    table.text     :handler
    table.string   :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.string   :locked_by
    table.datetime :failed_at
    table.timestamps
  end
end

class SomeJob
  def perform
    "Hello"
  end
end

Benchmark.bm(10) do |x|
  x.report("no index:") do
    3_000.times do
      Delayed::Job.enqueue(SomeJob.new)
    end
  end
  x.report("work:") do
    w = Delayed::Worker.new
    w.single_use = true
    w.start
  end
end

ActiveRecord::Schema.define do
  drop_table :delayed_jobs

  create_table :delayed_jobs, :force => true do |table|
    table.integer  :priority, :default => 0
    table.integer  :attempts, :default => 0
    table.text     :handler
    table.string   :last_error
    table.datetime :run_at
    table.datetime :locked_at
    table.string   :locked_by
    table.datetime :failed_at
    table.timestamps
  end

  add_index :delayed_jobs, :priority
  add_index :delayed_jobs, :run_at
  add_index :delayed_jobs, :locked_at
end

Benchmark.bm(10) do |x|
  x.report("index:") do
    3_000.times do
      Delayed::Job.enqueue(SomeJob.new)
    end
  end
  x.report("work:") do
    w = Delayed::Worker.new
    w.single_use = true
    w.start
  end
end

