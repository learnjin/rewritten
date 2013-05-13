require 'sinatra/base'
require 'erb'
require 'rewritten'
require 'rewritten/version'
require 'time'

module Rewritten
  class Server < Sinatra::Base

    dir = File.dirname(File.expand_path(__FILE__))

    set :views,  "#{dir}/server/views"
    set :public_folder, "#{dir}/server/public"
    set :static, true

    helpers do
      include Rack::Utils
      alias_method :h, :escape_html

      def current_section
        url_path request.path_info.sub('/','').split('/')[0].downcase
      end

      def current_page
        url_path request.path_info.sub('/','')
      end

      def url_path(*path_parts)
        [ path_prefix, path_parts ].join("/").squeeze('/')
      end
      alias_method :u, :url_path

      def path_prefix
        request.env['SCRIPT_NAME']
      end

      def class_if_current(path = '')
        'class="current"' if current_page[0, path.size] == path
      end

      def tab(name)
        dname = name.to_s.downcase
        path = url_path(dname)
        "<li #{class_if_current(path)}><a href='#{path}'>#{name}</a></li>"
      end

      def tabs
        Rewritten::Server.tabs
      end

      def redis_get_size(key)
        case Resque.redis.type(key)
        when 'none'
          []
        when 'list'
          Resque.redis.llen(key)
        when 'set'
          Resque.redis.scard(key)
        when 'string'
          Resque.redis.get(key).length
        when 'zset'
          Resque.redis.zcard(key)
        end
      end

      def redis_get_value_as_array(key, start=0)
        case Resque.redis.type(key)
        when 'none'
          []
        when 'list'
          Resque.redis.lrange(key, start, start + 20)
        when 'set'
          Resque.redis.smembers(key)[start..(start + 20)]
        when 'string'
          [Resque.redis.get(key)]
        when 'zset'
          Resque.redis.zrange(key, start, start + 20)
        end
      end

      def extract_translations
        text = params[:translations] or ""
        text.split("\n").map(&:strip).reject(&:empty?)
      end

      def show_args(args)
        Array(args).map { |a| a.inspect }.join("\n")
      end

      def worker_hosts
        @worker_hosts ||= worker_hosts!
      end

      def worker_hosts!
        hosts = Hash.new { [] }

        Resque.workers.each do |worker|
          host, _ = worker.to_s.split(':')
          hosts[host] += [worker.to_s]
        end

        hosts
      end

      def partial?
        @partial
      end

      def partial(template, local_vars = {})
        @partial = true
        erb(template.to_sym, {:layout => false}, local_vars)
      ensure
        @partial = false
      end

      def poll
        if @polling
          text = "Last Updated: #{Time.now.strftime("%H:%M:%S")}"
        else
          text = "<a href='#{u(request.path_info)}.poll' rel='poll'>Live Poll</a>"
        end
        "<p class='poll'>#{text}</p>"
      end

    end # enf of helpers
   

    def show(page, layout = true)
      begin
        erb page.to_sym, {:layout => layout}, :rewritten => Rewritten
      rescue Errno::ECONNREFUSED
        erb :error, {:layout => false}, :error => "Can't connect to Redis! (#{Rewritten.redis_id})"
      end
    end
    
    def show_for_polling(page)
      content_type "text/html"
      @polling = true
      show(page.to_sym, false).gsub(/\s{1,}/, ' ')
    end


    ################################################################################


    get "/?" do
      redirect url_path(:translations)
    end

    get "/translations" do
      @size = 0
      @start = params[:start].to_i

      if params[:f] && params[:f] != ""
        @translations = []

        keys = Rewritten.redis.keys("*#{params[:f]}*")
        keys.each do |key|
          prefix, url = key.split(":") 
          if prefix == "from"
            to = Rewritten.redis.get("from:#{url}") 
            @translations << [url, to]
          elsif prefix == "to"
            from = Rewritten.get_current_translation(url) 
            @translations << [from, url]
          end
        end

        @size = @translations.size
        @translations = @translations[params[:start].to_i..params[:start].to_i+Rewritten.per_page-1]

      else
        @size = Rewritten.num_froms
        froms = Rewritten.all_froms[@start, @start+Rewritten.per_page-1]
        @translations = froms.map{|f| [f, Rewritten.redis.get("from:#{f}")]}
      end


      show 'translations'
    end

    get "/new" do 
      @translations = []
      show "new"
    end

    get "/edit" do
      @old_to = @to = params[:to]
      @translations = Rewritten.get_all_translations(@to)
      show "edit"
    end

    post "/edit" do

      @old_to = params[:old].strip
      @to = params[:to].strip
      @translations = extract_translations

      if @to != '' and @translations.size > 0

        # delete old translations
        Rewritten.remove_all_translations(@old_to)
        # create new translations
        
        Rewritten.add_translations(@to, @translations)

        redirect u("/to?to=#{escape(@to)}")
      else
        show "edit"
      end

    end

    post "/translations" do
      @to = params[:to].strip
      @translations = extract_translations 
      if @to != '' && @translations.size > 0
        Rewritten.add_translations(@to, @translations)
        redirect u('translations')
      else
        show "new"
      end
    end

    get "/to" do
      translations = Rewritten.z_range(params[:to], 0, -1) 
      show "to" 
    end

    get "/cleanup" do
      # find keys that have no target
      @from_without_tos= []
      Rewritten.all_froms.each do |from|
        if Rewritten.redis.get("from:#{from}").empty?
          @from_without_tos << from
        end
      end
      
      show "cleanup"
    end

    get "/delete" do
      @from = params[:from]
      @to = params[:to]
      show "delete"
    end

    post '/delete' do
      from = params[:from]
      to   = params[:to]
      Rewritten.remove_translation(from, to)
      redirect u("/")
    end

    get "/delete_all" do
      @to = params[:to]
      show "delete_all"
    end

    post "/delete_all" do
      Rewritten.remove_all_translations(params[:to])
      redirect u("/")
    end

    get "/hits" do
      show "hits"
    end

    get "/hits/clear" do
      show "clear_hits"
    end

    post "/hits/clear" do
      Rewritten.redis.del("hits")
      redirect u("/hits") 
    end

    def self.tabs
      @tabs ||= ["Translations", "Hits"] 
    end

  end
end


