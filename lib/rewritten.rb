require 'redis/namespace'
require 'rewritten/version'
require 'rewritten/helpers'
require 'rack/dummy'
require 'rack/url'
require 'rack/record'
require 'rack/html'
require 'rack/subdomain'
require 'rack/canonical'
require 'rewritten/document'

module Rewritten
  include Helpers
  extend self

  # Accepts:
  #   1. A 'hostname:port' String
  #   2. A 'hostname:port:db' String (to select the Redis db)
  #   3. A 'hostname:port/namespace' String (to set the Redis namespace)
  #   4. A Redis URL String 'redis://host:port'
  #   5. An instance of `Redis`, `Redis::Client`, `Redis::DistRedis`,
  #      or `Redis::Namespace`.
  def redis=(server)
    case server
    when String
      if server =~ /redis\:\/\//
        redis = Redis.connect(:url => server, :thread_safe => true)
      else
        server, namespace = server.split('/', 2)
        host, port, db = server.split(':')
        redis = Redis.new(:host => host, :port => port,
          :thread_safe => true, :db => db)
      end
      namespace ||= :rewritten

      @redis = Redis::Namespace.new(namespace, :redis => redis)
    when Redis::Namespace
      @redis = server
    else
      @redis = Redis::Namespace.new(:rewritten, :redis => server)
    end
  end

  def translate_partial=(yes_or_no)
    @translate_partial = yes_or_no
  end

  def translate_partial?
    @translate_partial
  end

  # Returns the current Redis connection. If none has been created, will
  # create a new one.
  def redis
    return @redis if @redis
    self.redis = Redis.respond_to?(:connect) ? Redis.connect : "localhost:6379"
    self.redis
  end

  def redis_id
    # support 1.x versions of redis-rb
    if redis.respond_to?(:server)
      redis.server
    elsif redis.respond_to?(:nodes) # distributed
      redis.nodes.map { |n| n.id }.join(', ')
    else
      redis.client.id
    end
  end

  # The `before_first_fork` hook will be run in the **parent** process
  # only once, before forking to run the first job. Be careful- any
  # changes you make will be permanent for the lifespan of the
  # worker.
  #
  # Call with a block to set the hook.
  # Call with no arguments to return the hook.
  def before_first_fork(&block)
    block ? (@before_first_fork = block) : @before_first_fork
  end

  # Set a proc that will be called in the parent process before the
  # worker forks for the first time.
  def before_first_fork=(before_first_fork)
    @before_first_fork = before_first_fork
  end

  # The `before_fork` hook will be run in the **parent** process
  # before every job, so be careful- any changes you make will be
  # permanent for the lifespan of the worker.
  #
  # Call with a block to set the hook.
  # Call with no arguments to return the hook.
  def before_fork(&block)
    block ? (@before_fork = block) : @before_fork
  end

  # Set the before_fork proc.
  def before_fork=(before_fork)
    @before_fork = before_fork
  end

  # The `after_fork` hook will be run in the child process and is passed
  # the current job. Any changes you make, therefore, will only live as
  # long as the job currently being processed.
  #
  # Call with a block to set the hook.
  # Call with no arguments to return the hook.
  def after_fork(&block)
    block ? (@after_fork = block) : @after_fork
  end

  # Set the after_fork proc.
  def after_fork=(after_fork)
    @after_fork = after_fork
  end

  def to_s
    "Rewritten Client connected to #{redis_id}"
  end

  # If 'inline' is true Resque will call #perform method inline
  # without queuing it into Redis and without any Resque callbacks.
  # The 'inline' is false Resque jobs will be put in queue regularly.
  def inline?
    @inline
  end
  alias_method :inline, :inline?

  def inline=(inline)
    @inline = inline
  end

  #
  # translations 
  #

  def add_translation(line, to)
    from, flags = line.split(/\s+/)

    flags = flags.scan(/\[(\w+)\]/).first if flags

    redis.hset("from:#{from}", :to, to)
    redis.hset("from:#{from}", :flags, flags) if flags

    redis.sadd(:froms, from) 
    redis.sadd(:tos, to) 
    score = redis.zcard("to:#{to}") || 0
    redis.zadd("to:#{to}", score, from)  
  end

  def add_translations(to, froms)
    froms.each {|from|  add_translation(from, to)}
  end

  def num_translations(to)
    Rewritten.redis.zcard("to:#{to}")
  end

  def remove_translation(from, to)
    Rewritten.redis.del("from:#{from}")
    Rewritten.redis.srem(:froms, from)
    Rewritten.redis.zrem("to:#{to}", from)
    Rewritten.redis.srem(:tos, to) if num_translations(to) == 0
 end

  def remove_all_translations(to)
    get_all_translations(to).each do |from|
      Rewritten.remove_translation(from, to)
    end
  end

  def clear_translations
    Rewritten.redis.del(*Rewritten.redis.keys) unless Rewritten.redis.keys.empty?
  end

  # Returns an array of all known source URLs (that are to translated)
  def froms
    Array(redis.smembers(:froms))
  end

  def all_froms
    Array(redis.smembers(:froms))
  end

  def all_tos
    Array(Rewritten.redis.smembers(:tos))
  end

  def translate(from)
    redis.hget("from:#{from}", :to)
  end

  def get_all_translations(to)
    Rewritten.redis.zrange("to:#{to}", 0, -1)
  end

  def get_current_translation(path, tail=nil)

    uri = URI.parse(path)

    # find directly
    translation = Rewritten.z_range("to:#{path}", -1)
   
    unless translation 
      translation = Rewritten.z_range("to:#{uri.path}", -1)
    end

    if translation.nil?
      if translate_partial? && path.count('/') > 1
        parts = path.split('/')
        shorter_path = parts.slice(0, parts.size-1).join('/')
        appendix = parts.last + (tail ? "/" + tail : "")
        return get_current_translation(shorter_path, appendix) 
      else
        return path
      end
    end

    complete_path = (tail ? translation+"/"+tail : translation)
    translated_uri = URI.parse(complete_path)
    uri.path = translated_uri.path
    uri.query = [translated_uri.query, uri.query].compact.join('&')
    uri.query = nil if uri.query == ''
    uri.to_s
  end


  # infinitive for translations only!
  def infinitive(some_from)

    conjugated = some_from.chomp('/')

    to = translate(conjugated)
    to = translate(conjugated.split('?')[0]) unless to

    if to.nil? && translate_partial? && conjugated.count('/') > 1 
      parts = conjugated.split('/')
      shorter_path = parts.slice(0, parts.size-1).join('/')
      infinitive(shorter_path)
    else
      conjugated = get_current_translation(to) if to
      conjugated.split('?')[0].chomp('/')
    end
  end


  def base_from(some_from)
    base_from = some_from.split('?')[0].chomp('/')
    if translate(some_from)
      some_from
    elsif translate(base_from)
      base_from
    elsif translate_partial? && base_from.count('/') > 1
      parts = base_from.split('/')
      base_from(parts.slice(0,parts.size-1).join('/'))
    else
      nil
    end
  end

  def appendix(some_from)
    base = base_from(some_from) || ''
    result = some_from.partition( base ).last
    result.chomp('/')
  end

  def get_flag_string(from)
    Rewritten.redis.hget("from:#{from}", :flags)||""
  end

  def has_flag?(from, c)
    return false unless Rewritten.redis.exists("from:#{from}")
    get_flag_string(from).index(c) != nil
  end

  def full_line(from)
    flags = get_flag_string(from)

    if flags == ""
      from
    else
      "#{from} [#{flags}]" 
    end

  end

  def exist_translation_for?(path)
    get_current_translation(path) != path
  end

  def add_hit(path, code, content_type)
    h = {:path => path, :code => code, :content_type => content_type}
    Rewritten.redis.sadd("hits", encode(h) )
  end

  def all_hits
    Rewritten.redis.smembers("hits").map{|e| decode(e)}
  end

  def includes?(path)

    result = Rewritten.redis.hget("from:#{path.chomp('/')}", :to)
    result = Rewritten.redis.hget("from:#{path.split('?')[0]}", :to) unless result

    if result.nil? && translate_partial? && path.count('/') > 1
      parts = path.split('/')
      includes?( parts.slice(0,parts.size-1).join('/') )
    else
      result
    end

  end

  # return the number of froms
  def num_froms
    redis.scard(:froms).to_i
  end

  # Does the dirty work of fetching a range of items from a Redis list
  # and converting them into Ruby objects.
  def z_range(key, start = 0, count = 1)
    if count == 1
      redis.zrange(key, start, start)[0]
    else
      Array(redis.zrange(key, start, start+count-1)).map do |item|
        item
      end
    end
  end

  # Returns an array of all known Resque queues as strings.
  def queues
    Array(redis.smembers(:queues))
  end

  # Returns an array of all known URL targets.
  def targets 
    Array(redis.smembers(:targets))
  end

  # Given a queue name, completely deletes the queue.
  def remove_queue(queue)
    redis.srem(:queues, queue.to_s)
    redis.del("queue:#{queue}")
  end

  # Used internally to keep track of which queues we've created.
  # Don't call this directly.
  def watch_queue(queue)
    redis.sadd(:queues, queue.to_s)
  end

  
  #
  # stats
  #

  # Returns a hash, similar to redis-rb's #info, of interesting stats.
  def info
    return {
      :pending   => queues.inject(0) { |m,k| m + size(k) },
      #:processed => Stat[:processed],
      #:queues    => queues.size,
      #:workers   => workers.size.to_i,
      #:working   => working.size,
      #:failed    => Stat[:failed],
      :servers   => [redis_id],
      :environment  => ENV['RAILS_ENV'] || ENV['RACK_ENV'] || 'development'
    }
  end

  # Returns an array of all known Resque keys in Redis. Redis' KEYS operation
  # is O(N) for the keyspace, so be careful - this can be slow for big databases.
  def keys
    redis.keys("*").map do |key|
      key.sub("#{redis.namespace}:", '')
    end
  end

  def per_page
    20
  end

  
end

