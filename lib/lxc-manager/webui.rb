# coding: utf-8

require 'uri'

require 'bundler/setup'

require 'sinatra/base'
require 'sinatra/reloader'

require_relative '../lxc-manager'

class LxcManager
	class WebUI < Sinatra::Base
		config  = YAML.load_file( LxcManager::CONFIG_FILE_PATH )
		webui_url = URI.parse( config['webui_url'] )

		set :environment, :development

		set :root, "#{File.dirname(__FILE__)}/webui"
		set :bind, webui_url.host
		set :port, webui_url.port

		enable :sessions
		set :session_secret, 'session_secret'

		enable :logging
		use Rack::CommonLogger, LxcManager::Logger.instance

		configure :development do
			register Sinatra::Reloader
		end

		get '/' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					redirect '/overview'
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				redirect '/'
			end
		end

		get '/login' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /login"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}: redirect to /overview"
					redirect '/overview'
				else
					erb :login, layout: nil
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				redirect '/'
			end
		end

		post '/login' do
			begin
				logger = LxcManager::Logger.instance
				lxc_manager = LxcManager.new
				logger.info "POST /login"
				logger.debug "params: #{params}"
				if session[:user_id]
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}: redirect to /overview"
					redirect '/overview'
				else
					user = lxc_manager.authenticate_user_by_name( params[:name], params[:password] )
					session[:user_id] = user.id
					redirect '/overview'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :create_user, locals: locals
				erb :login, layout: nil, locals: locals
			end
		end

		get '/logout' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /logout"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					erb :logout, layout: nil
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				redirect '/'
			end
		end

		post '/logout' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /logout"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					session.delete :user_id
				else
					logger.info 'No session[:user_id]: Redirect to /login'
				end
				redirect '/login'
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				redirect '/'
			end
		end

		get '/overview' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /overview"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["users"]       = lxc_manager.users
					locals["hosts"]       = lxc_manager.hosts
					locals["distros"]     = lxc_manager.distros
					locals["networks"]    = lxc_manager.networks
					locals["containers"]  = lxc_manager.containers
					locals["snapshots"]   = lxc_manager.snapshots
					erb :overview, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				redirect '/'
			end
		end

		get '/users' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /users"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["users"]       = lxc_manager.users
					erb :users, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :overview, locals: locals
			end
		end

		get '/create_user' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_user"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					erb :create_user, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["users"]       = lxc_manager.users
				locals["e"]           = e
				erb :users, locals: locals
			end
		end

		post '/create_user' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_user"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_user params[:name], params[:password]
					redirect "/users"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["name"]        = params[:name]
				locals["password"]    = params[:password]
				locals["e"]           = e
				erb :create_user, locals: locals
			end
		end

		get '/hosts' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /hosts"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["hosts"]       = lxc_manager.hosts
					erb :hosts, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :overview, locals: locals
			end
		end

		get '/create_host' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_host"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					erb :create_host, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["hosts"]       = lxc_manager.hosts
				locals["e"]           = e
				erb :hosts, locals: locals
			end
		end

		post '/create_host' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_host"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_host params[:name], params[:v4_address]
					redirect "/hosts"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["name"]        = params[:name]
				locals["v4_address"]  = params[:v4_address]
				locals["e"]           = e
				erb :create_host, locals: locals
			end
		end

		get '/destroy_host/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_host/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["host"]  = lxc_manager.hosts.find( params[:id] )
					erb :destroy_host, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["hosts"]       = lxc_manager.hosts
				locals["e"]           = e
				erb :hosts, locals: locals
			end
		end

		post '/destroy_host/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_host/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.destroy_host params[:id]
					redirect "/hosts"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["host"]        = lxc_manager.hosts.find( params[:id] )
				locals["e"]           = e
				erb :destroy_host, locals: locals
			end
		end

		get '/distros' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /distros"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["distros"]     = lxc_manager.distros
					erb :distros, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :overview, locals: locals
			end

		end

		get '/create_distro' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_distro"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					erb :create_distro, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["distros"]     = lxc_manager.distros
				locals["e"]           = e
				erb :distros, locals: locals
			end
		end

		post '/create_distro' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_distro"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_distro params[:name], params[:iso], params[:template]
					redirect "/distros"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["name"]        = params[:name]
				locals["iso"]         = params[:iso]
				locals["template"]    = params[:template]
				locals["e"]           = e
				erb :create_distro, locals: locals
			end
		end

		get '/destroy_distro/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_distro/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["distro"]      = lxc_manager.distros.find( params[:id] )
					erb :destroy_distro, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["distros"]     = lxc_manager.distros
				locals["e"]           = e
				erb :distros, locals: locals
			end
		end

		post '/destroy_distro/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_distro/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.destroy_distro params[:id]
					redirect "/distros"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["distro"]      = lxc_manager.distros.find( params[:id] )
				locals["e"]           = e
				erb :destroy_distro, locals: locals
			end
		end

		get '/networks' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /networks"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["networks"]    = lxc_manager.networks
					erb :networks, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :overview, locals: locals
			end
		end

		get '/create_network' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_network"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					erb :create_network, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["networks"]    = lxc_manager.networks
				erb :networks, locals: locals
			end
		end

		post '/create_network' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_network"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_network params[:name], params[:v4_address], params[:v4_prefix]
					redirect "/networks"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["name"]        = params[:name]
				locals["v4_address"]  = params[:v4_address]
				locals["v4_prefix"]   = params[:v4_prefix]
				locals["e"]           = e
				erb :create_network, locals: locals
			end
		end

		get '/destroy_network/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_network/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["network"]     = lxc_manager.networks.find( params[:id] )
					erb :destroy_network, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["networks"]    = lxc_manager.networks
				erb :networks, locals: locals
			end
		end

		post '/destroy_network/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_network/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.destroy_network params[:id]
					redirect "/networks"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["network"]     = lxc_manager.networks.find( params[:id] )
				locals["e"]           = e
				erb :destroy_network, locals: locals
			end
		end

		get '/containers' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /containers"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["containers"]  = lxc_manager.containers
					erb :containers, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :overview, locals: locals
			end
		end

		get '/create_container' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_container"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["distros"]     = lxc_manager.distros
					erb :create_container, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :containers, locals: locals
			end
		end

		post '/create_container' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_container"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_container params[:name], params[:hostname], params[:description], params[:distro_id]
					redirect "/containers"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["distros"]     = lxc_manager.distros
				locals["name"]        = params[:name]
				locals["hostname"]    = params[:hostname]
				locals["description"] = params[:description]
				locals["distro_id"]   = params[:distro_id]
				locals["e"]           = e
				erb :create_container, locals: locals
			end
		end

		get '/destroy_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :destroy_container, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :containers, locals: locals
			end
		end

		post '/destroy_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.destroy_container params[:id]
					redirect "/containers"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["e"]           = e
				erb :destroy_container, locals: locals
			end
		end

		get '/container_detail/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /container_detail/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]   = lxc_manager.containers.find( params[:id] )
					locals['server_name'] = request.env['SERVER_NAME']
					erb :container_detail, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :containers, locals: locals
			end
		end

		get '/edit_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /edit_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :edit_container, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/edit_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /edit_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.edit_container params[:id], params[:name], params[:hostname], params[:description]
					redirect "/container_detail/#{params[:id]}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["name"]        = params[:name]
				locals["hostname"]    = params[:hostname]
				locals["description"] = params[:description]
				locals["e"]           = e
				erb :edit_container, locals: locals
			end
		end

		get '/create_interface/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_interface/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					locals["networks"]  = lxc_manager.networks
					erb :create_interface, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/create_interface/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_interface/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_interface params[:network_id], params[:id], params[:name], params[:v4_address]
					redirect "/container_detail/#{params[:id]}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["networks"]    = lxc_manager.networks
				locals["network_id"]  = params[:network_id]
				locals["name"]        = params[:name]
				locals["v4_address"]  = params[:v4_address]
				locals["e"]           = e
				erb :create_interface, locals: locals
			end
		end

		get '/edit_interface/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /edit_interface/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["interface"]  = lxc_manager.interfaces.find( params[:id] )
					locals["networks"]  = lxc_manager.networks
					erb :edit_interface, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.interfaces.find( params[:id] ).container
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/edit_interface/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /edit_interface/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					container = lxc_manager.interfaces.find( params[:id] ).container
					lxc_manager.destroy_interface params[:id]
					lxc_manager.create_interface params[:network_id], container.id, params[:name], params[:v4_address]
					redirect "/container_detail/#{container.id}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["interface"]   = lxc_manager.interfaces.find( params[:id] )
				locals["networks"]    = lxc_manager.networks
				locals["network_id"]  = params[:network_id]
				locals["name"]        = params[:name]
				locals["v4_address"]  = params[:v4_address]
				locals["e"]           = e
				erb :edit_interface, locals: locals
			end
		end

		get '/destroy_interface/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_interface/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["interface"]  = lxc_manager.interfaces.find( params[:id] )
					erb :destroy_interface, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.interfaces.find( params[:id] ).container
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/destroy_interface/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_interface/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					container = lxc_manager.interfaces.find( params[:id] ).container
					lxc_manager.destroy_interface params[:id]
					redirect "/container_detail/#{container.id}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["interface"]   = lxc_manager.interfaces.find( params[:id] )
				locals["e"]           = e
				erb :destroy_interface, locals: locals
			end
		end

		get '/create_napt/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_napt/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :create_napt, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/create_napt/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_napt/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_napt params[:id], params[:name], params[:dport]
					redirect "/container_detail/#{params[:id]}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["name"]        = params[:name]
				locals["dport"]       = params[:dport]
				locals["e"]           = e
				erb :create_napt, locals: locals
			end
		end

		get '/edit_napt/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /edit_napt/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["napt"]        = lxc_manager.napts.find( params[:id] )
					erb :edit_napt, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.napts.find( params[:id] ).container
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/edit_napt/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /edit_napt/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					container = lxc_manager.napts.find( params[:id] ).container
					lxc_manager.destroy_napt params[:id]
					lxc_manager.create_napt container.id, params[:name], params[:dport]
					redirect "/container_detail/#{container.id}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["napt"]        = lxc_manager.napts.find( params[:id] )
				locals["name"]        = params[:name]
				locals["dport"]       = params[:dport]
				locals["e"]           = e
				erb :edit_napt, locals: locals
			end
		end

		get '/destroy_napt/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_napt/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["napt"]  = lxc_manager.napts.find( params[:id] )
					erb :destroy_napt, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.napts.find( params[:id] ).container
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/destroy_napt/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_napt/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					container = lxc_manager.napts.find( params[:id] ).container
					lxc_manager.destroy_napt params[:id]
					redirect "/container_detail/#{container.id}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["napt"]        = lxc_manager.napts.find( params[:id] )
				locals["e"]           = e
				erb :destroy_napt, locals: locals
			end
		end

		get '/create_reverse_proxy/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_reverse_proxy/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :create_reverse_proxy, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/create_reverse_proxy/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_reverse_proxy/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_reverse_proxy params[:id], params[:name], params[:location], params[:proxy_port], params[:proxy_pass]
					redirect "/container_detail/#{params[:id]}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["name"]        = params[:name]
				locals["location"]    = params[:location]
				locals["proxy_port"]  = params[:proxy_port]
				locals["proxy_pass"]  = params[:proxy_pass]
				locals["e"]           = e
				erb :create_reverse_proxy, locals: locals
			end
		end

		get '/edit_reverse_proxy/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /edit_reverse_proxy/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["reverse_proxy"]  = lxc_manager.reverse_proxies.find( params[:id] )
					erb :edit_reverse_proxy, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.reverse_proxies.find( params[:id] ).container
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/edit_reverse_proxy/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /edit_reverse_proxy/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					container = lxc_manager.reverse_proxies.find( params[:id] ).container
					lxc_manager.destroy_reverse_proxy params[:id]
					lxc_manager.create_reverse_proxy container.id, params[:name], params[:location], params[:proxy_port], params[:proxy_pass]
					redirect "/container_detail/#{container.id}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"]   = lxc_manager
				locals["config"]        = lxc_manager.config
				locals["reverse_proxy"] = lxc_manager.reverse_proxies.find( params[:id] )
				locals["name"]          = params[:name]
				locals["location"]      = params[:location]
				locals["proxy_port"]    = params[:proxy_port]
				locals["proxy_pass"]    = params[:proxy_pass]
				locals["e"]             = e
				erb :edit_reverse_proxy, locals: locals
			end
		end

		get '/destroy_reverse_proxy/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_reverse_proxy/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"]   = lxc_manager
					locals["config"]        = lxc_manager.config
					locals["reverse_proxy"] = lxc_manager.reverse_proxies.find( params[:id] )
					erb :destroy_reverse_proxy, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.reverse_proxies.find( params[:id] ).container
				locals['server_name'] = request.env['SERVER_NAME']
				erb :container_detail, locals: locals
			end
		end

		post '/destroy_reverse_proxy/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_reverse_proxy/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					container = lxc_manager.reverse_proxies.find( params[:id] ).container
					lxc_manager.destroy_reverse_proxy params[:id]
					redirect "/container_detail/#{container.id}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"]   = lxc_manager
				locals["config"]        = lxc_manager.config
				locals["reverse_proxy"] = lxc_manager.reverse_proxies.find( params[:id] )
				locals["e"]             = e
				erb :destroy_reverse_proxy, locals: locals
			end
		end

		get '/start_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /start_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]   = lxc_manager.containers.find( params[:id] )
					locals["hosts"]       = lxc_manager.hosts
					erb :start_container, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :containers, locals: locals
			end
		end

		post '/start_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /start_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.start_container params[:id], params[:host_id]
					redirect "/containers"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["hosts"]       = lxc_manager.hosts
				locals["host_id"]     = params[:host_id]
				locals["e"]           = e
				erb :start_container, locals: locals
			end
		end

		get '/stop_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /stop_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :stop_container, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :containers, locals: locals
			end
		end

		post '/stop_container/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /stop_container/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.stop_container params[:id]
					redirect "/containers"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["e"]           = e
				erb :stop_container, locals: locals
			end
		end

		get '/snapshots' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /snapshots"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["containers"]  = lxc_manager.containers
					erb :snapshots, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["e"]           = e
				erb :overview, locals: locals
			end
		end

		get '/create_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :create_snapshot, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :snapshots, locals: locals
			end
		end

		post '/create_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_snapshot params[:id], params[:name], params[:description]
					redirect "/snapshots"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["name"]        = params[:name]
				locals["description"] = params[:description]
				locals["e"]           = e
				erb :create_snapshot, locals: locals
			end
		end

		get '/destroy_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /destroy_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["snapshot"]  = lxc_manager.snapshots.find( params[:id] )
					erb :destroy_snapshot, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :snapshots, locals: locals
			end
		end

		post '/destroy_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /destroy_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.destroy_snapshot params[:id]
					redirect "/snapshots"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["snapshot"]  = lxc_manager.snapshots.find( params[:id] )
				locals["e"]           = e
				erb :destroy_snapshot, locals: locals
			end
		end

		get '/snapshot_detail/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /snapshot_detail/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["snapshot"]    = lxc_manager.snapshots.find( params[:id] )
					erb :snapshot_detail, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :snapshots, locals: locals
			end
		end

		get '/edit_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /edit_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["snapshot"]  = lxc_manager.snapshots.find( params[:id] )
					erb :edit_snapshot, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["snapshot"]    = lxc_manager.snapshots.find( params[:id] )
				erb :snapshot_detail, locals: locals
			end
		end

		post '/edit_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /edit_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.edit_snapshot params[:id], params[:name], params[:description]
					redirect "/snapshot_detail/#{params[:id]}"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["snapshot"]    = lxc_manager.snapshots.find( params[:id] )
				locals["name"]        = params[:name]
				locals["description"] = params[:description]
				locals["e"]           = e
				erb :edit_snapshot, locals: locals
			end
		end

		get '/rollback_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /rollback_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["snapshot"]  = lxc_manager.snapshots.find( params[:id] )
					erb :rollback_snapshot, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :snapshots, locals: locals
			end
		end

		post '/rollback_snapshot/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /rollback_snapshot/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.rollback_snapshot params[:id]
					redirect "/snapshots"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["snapshot"]    = lxc_manager.snapshots.find( params[:id] )
				locals["e"]           = e
				erb :rollback_snapshot, locals: locals
			end
		end

		get '/promote/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /promote/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["container"]  = lxc_manager.containers.find( params[:id] )
					erb :promote, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :snapshots, locals: locals
			end
		end

		post '/promote/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /promote/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.promote params[:id]
					redirect "/snapshots"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["container"]   = lxc_manager.containers.find( params[:id] )
				locals["e"]           = e
				erb :promote, locals: locals
			end
		end

		get '/create_clone/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /create_clone/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					locals = Hash.new
					locals["lxc_manager"] = lxc_manager
					locals["config"]      = lxc_manager.config
					locals["snapshot"]    = lxc_manager.snapshots.find( params[:id] )
					erb :create_clone, locals: locals
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :snapshots, locals: locals
			end
		end

		post '/create_clone/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "POST /create_clone/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager.create_clone params[:id], params[:name], params[:hostname], params[:description]
					redirect "/snapshots"
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["snapshot"]    = lxc_manager.snapshots.find( params[:id] )
				locals["name"]        = params[:name]
				locals["hostname"]    = params[:hostname]
				locals["description"] = params[:description]
				locals["e"]           = e
				erb :create_clone, locals: locals
			end
		end

		get '/teraterm_macro/:id' do
			begin
				logger = LxcManager::Logger.instance
				logger.info "GET /teraterm_macro/#{params[:id]}"
				logger.debug "params: #{params}"
				if session[:user_id]
					lxc_manager = LxcManager.new
					logger.info "requested by #{lxc_manager.users.find( session[:user_id] ).name}"
					lxc_manager = lxc_manager
					config      = lxc_manager.config
					container   = lxc_manager.containers.find( params[:id] )
					server_name = request.env['SERVER_NAME']
					content_type 'text/turtle'
					attachment "login_#{params[:id]}.ttl"
					<<-EOB
					addr = '#{server_name}'
					port = '#{container.napts.find_by_name( 'management' ).sport}'
					username = 'root'
					password = 'rootroot'

					sprintf2 var '%s:%s /ssh /2 /auth=password /user=%s /passwd="%s"' addr port username password
					connect var
					EOB
				else
					logger.info 'No session[:user_id]: Redirect to /login'
					redirect '/login'
				end
			rescue => e
				logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
				lxc_manager = LxcManager.new
				locals = Hash.new
				locals["lxc_manager"] = lxc_manager
				locals["config"]      = lxc_manager.config
				locals["containers"]  = lxc_manager.containers
				erb :containers, locals: locals
			end
		end
	end
end

if __FILE__ == $0
	LxcManager::WebUI.run!
end
