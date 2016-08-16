# coding: utf-8

require 'thread'
require 'securerandom'

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

require_relative 'lxc-manager/logger'

require_relative 'lxc-manager/user'
require_relative 'lxc-manager/host'
require_relative 'lxc-manager/distro'
require_relative 'lxc-manager/network'
require_relative 'lxc-manager/container'
require_relative 'lxc-manager/interface'
require_relative 'lxc-manager/napt'
require_relative 'lxc-manager/reverse_proxy'
require_relative 'lxc-manager/snapshot'
require_relative 'lxc-manager/clone'

require_relative 'lxc-manager/cli-agent'
require_relative 'lxc-manager/lxc-controller'
require_relative 'lxc-manager/zfs-controller'
require_relative 'lxc-manager/repo-controller'
require_relative 'lxc-manager/host-controller'
require_relative 'lxc-manager/nginx-controller'
require_relative 'lxc-manager/network-controller'
require_relative 'lxc-manager/iptables-controller'

require_relative 'lxc-manager/host-resource-monitor'
require_relative 'lxc-manager/storage-resource-monitor'

class LxcManager
	attr_reader :config

	ROOT_DIR_PATH       ||= "#{File.dirname(__FILE__)}/.."
	CONFIG_DIR_PATH     ||= "#{ROOT_DIR_PATH}/config"
	CONFIG_FILE_PATH    ||= "#{CONFIG_DIR_PATH}/setting.yml"
	CONFIG_DB_FILE_PATH ||= "#{CONFIG_DIR_PATH}/database.yml"

	DRY_RUN ||= false

	@@m = Mutex.new

	def initialize
		@logger = LxcManager::Logger.instance
		@config = YAML.load_file( CONFIG_FILE_PATH )

		ActiveRecord::Base.configurations = YAML.load_file( CONFIG_DB_FILE_PATH )
		ActiveRecord::Base.establish_connection( :development )
	end

	def preconfigure locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		network = nil
		lock_success = false
		update_db_success = false
		create_network_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "reconfigure distros start"
			RepoController.reconfigure @config, distros
			@logger.debug "#{self.class}##{__method__}: " + "reconfigure distros end"

			@logger.debug "#{self.class}##{__method__}: " + "configure hosts start"
			Host.all.each{ |host|
				HostController.configure @config, host
			}
			@logger.debug "#{self.class}##{__method__}: " + "configure hosts end"

			@logger.debug "#{self.class}##{__method__}: " + "configure networks start"
			Network.all.each{ |network|
				NetworkController.configure_all_hosts @config, network, Host.all
			}
			@logger.debug "#{self.class}##{__method__}: " + "configure networks end"

			@logger.debug "#{self.class}##{__method__}: " + "configure napts start"
			IptablesController.reset @config, Napt.all
			@logger.debug "#{self.class}##{__method__}: " + "configure napts end"
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def users
		User.all
	end

	def create_user name, password, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "name: #{name}, password: #{password}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		user = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				user = User.new
				user[:name]          = name
				user[:password_salt] = User.generate_salt
				user[:password_hash] = User.generate_hash( password, user[:password_salt] )
				user.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			user
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_user id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		user = nil
		lock_success = false
		update_db_success = false
		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				user = User.find( id )
				user.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			user
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def authenticate_user id, password
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}, password: #{password}"
		user = User.authenticate_by_id id, password
		@logger.debug "#{self.class}##{__method__}: " + "authentication success"
		user
	end

	def authenticate_user_by_name name, password
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "name: #{name}, password: #{password}"
		user = User.authenticate_by_name name, password
		@logger.debug "#{self.class}##{__method__}: " + "authentication success"
		user
	end

	def hosts
		@logger.info "#{self.class}##{__method__}"
		Host.all
	end

	def create_host name, v4_address, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "name: #{name}, v4_address: #{v4_address}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		host = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				host = Host.new
				host[:name]       = name
				host[:v4_address] = v4_address
				host.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "configure host start"
				HostController.configure @config, host
				@logger.debug "#{self.class}##{__method__}: " + "configure host end"

				@logger.debug "#{self.class}##{__method__}: " + "configure networks start"
				Network.all.each{ |network|
					NetworkController.configure_host @config, network, host
				}
				@logger.debug "#{self.class}##{__method__}: " + "configure networks end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			host
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_host id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		host = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				host = Host.find( id )
				host.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
				host
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			host
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def distros
		@logger.info "#{self.class}##{__method__}"
		Distro.all
	end

	def create_distro name, iso, template, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "name: #{name}, iso: #{iso}, template: #{template}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		distro = nil
		lock_success = false
		update_db_success = false
		create_repo_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				distro = Distro.new
				distro[:name]     = name
				distro[:iso]      = iso
				distro[:template] = template
				distro.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
				@logger.debug "#{self.class}##{__method__}: " + "create repo start"
				RepoController.create @config, distro
				create_repo_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create repo end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			distro
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_distro id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		distro = nil
		lock_success = false
		update_db_success = false
		destroy_repo_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				distro = Distro.find( id )
				distro.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
				distro
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			@logger.debug "#{self.class}##{__method__}: " + "destroy repo start"
			RepoController.destroy @config, distro
			destroy_repo_success = true
			@logger.debug "#{self.class}##{__method__}: " + "destroy repo end"

			distro
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def networks
		@logger.info "#{self.class}##{__method__}"
		Network.all
	end

	def create_network name, v4_address, v4_prefix, vlan_id: nil, host_v4_address: nil, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "name: #{name}, v4_address: #{v4_address}, v4_prefix: #{v4_prefix}, vlan_id: #{vlan_id}, host_v4_address: #{host_v4_address}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		network = nil
		lock_success = false
		update_db_success = false
		create_network_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				network = Network.new
				network[:name]       = name
				network[:vlan_id]    = vlan_id || Network.assign_vlan_id( @config )
				network[:v4_address] = v4_address
				network[:v4_prefix]  = v4_prefix
				if host_v4_address
					network[:host_v4_address] = host_v4_address
				end
				network.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
				@logger.debug "#{self.class}##{__method__}: " + "create network start"
				hosts = Host.all
				NetworkController.create @config, network, hosts
				create_network_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create network end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			network
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_network id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		network = nil
		lock_success = false
		update_db_success = false
		destroy_network_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				network = Network.find( id )
				network.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
				@logger.debug "#{self.class}##{__method__}: " + "destroy network start"
				hosts = Host.all
				NetworkController.destroy @config, network, hosts
				destroy_network_success = true
				@logger.debug "#{self.class}##{__method__}: " + "destroy network end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			network
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def containers
		@logger.info "#{self.class}##{__method__}"
		Container.all
	end

	def create_container name, hostname, description, distro_id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "name: #{name}, hostname: #{hostname}, description: #{description}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		container = nil
		management_interface = nil
		management_napt = nil
		lock_success = false
		update_db_success = false
		create_zfs_success = false
		exportfs_success = false
		create_management_interface_success = false
		create_management_napt_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				container = Container.new
				container[:name]        = name
				container[:hostname]    = hostname
				container[:description] = description
				container[:distro_id]   = distro_id
				container[:state]       = LxcManager::Container::STOPPED
				container.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "create zfs start"
				ZfsController.create @config, container
				create_zfs_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create zfs end"

				@logger.debug "#{self.class}##{__method__}: " + "create lxc start"
				LxcController.create @config, container
				@logger.debug "#{self.class}##{__method__}: " + "create lxc end"

				@logger.debug "#{self.class}##{__method__}: " + "export lxc start"
				LxcController.exportfs @config, container
				exportfs_success = true
				@logger.debug "#{self.class}##{__method__}: " + "export lxcs end"

				@logger.debug "#{self.class}##{__method__}: " + "update lxc start"
				LxcController.update_parameters @config, container
				@logger.debug "#{self.class}##{__method__}: " + "update lxc end"

				management_network   = Network.find_by_name( 'management' )
				mng_nw_v4_gateway    = @config['management_network_bridge_v4_address']

				@logger.debug "#{self.class}##{__method__}: " + "create management interface start"
				management_interface = self.create_interface management_network.id, container.id, 'management', v4_gateway: mng_nw_v4_gateway, locked: true
				create_management_interface_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create management interface end"

				@logger.debug "#{self.class}##{__method__}: " + "create management napt start"
				management_napt      = self.create_napt container.id, 'management', '22', locked: true
				create_management_napt_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create management napt end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			container
		rescue
			if create_management_napt_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy management napt start"
				IptablesController.destroy @config, management_napt
				@logger.debug "#{self.class}##{__method__}: " + "destroy management napt end"
			end

			if create_management_interface_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy management interface start"
				LxcController.update_interfaces @config, container
				@logger.debug "#{self.class}##{__method__}: " + "destroy management interface end"
			end

			if exportfs_success
				@logger.debug "#{self.class}##{__method__}: " + "unexport lxc start"
				LxcController.unexportfs @config, container
				@logger.debug "#{self.class}##{__method__}: " + "unexport lxcs end"
			end

			if create_zfs_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy zfs start"
				ZfsController.destroy @config, container
				@logger.debug "#{self.class}##{__method__}: " + "destroy zfs end"
			end

			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_container id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		container = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			container = Container.find( id )
			container.reverse_proxies.each{ |reverse_proxy|
				destroy_reverse_proxy reverse_proxy.id, locked: true
			}
			container.napts.each{ |napt|
				destroy_napt napt.id, locked: true
			}
			container.interfaces.each{ |interface|
				destroy_interface interface.id, locked: true
			}

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				container.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "unexport lxc start"
				LxcController.unexportfs @config, container
				@logger.debug "#{self.class}##{__method__}: " + "unexport lxc end"

				@logger.debug "#{self.class}##{__method__}: " + "destroy zfs start"
				ZfsController.destroy @config, container
				@logger.debug "#{self.class}##{__method__}: " + "destroy zfs end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			container
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def edit_container id, name, hostname, description, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}, name: #{name}, hostname: #{hostname}, description: #{description}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		container = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				container = Container.find( id )
				container[:name]        = name
				container[:hostname]    = hostname
				container[:description] = description
				container.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update parameters start"
				LxcController.update_parameters @config, container
				@logger.debug "#{self.class}##{__method__}: " + "update parameters end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			container
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def start_container id, host_id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}, host_id: #{host_id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		container = nil
		lock_success = false
		update_db_success = false
		start_container_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				container = Container.find( id )
				container['host_id'] = host_id
				container['state']   = LxcManager::Container::RUNNING
				container.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "start container start"
				LxcController.start @config, container
				start_container_success = true
				@logger.debug "#{self.class}##{__method__}: " + "start container end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			container
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def stop_container id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		container = nil
		lock_success = false
		update_db_success = false
		stop_container_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				container = Container.find( id )

				@logger.debug "#{self.class}##{__method__}: " + "stop container start"
				LxcController.stop @config, container
				stop_container_success = true
				@logger.debug "#{self.class}##{__method__}: " + "stop container end"

				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				container['host_id'] = nil
				container['state']   = LxcManager::Container::STOPPED
				container.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			container
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def interfaces
		@logger.info "#{self.class}##{__method__}"
		Interface.all
	end

	def create_interface network_id, container_id, name, v4_address=nil, v4_gateway: nil, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "network_id: #{network_id}, container_id: #{container_id}, name: #{name}, v4_address: #{v4_address}, v4_gateway: #{v4_gateway}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		interface = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				interface = Interface.new
				interface[:network_id]   = network_id
				interface[:container_id] = container_id
				interface[:name]         = name
				interface[:v4_address]   = v4_address || interface.assign_v4_address
				if v4_gateway
					interface[:v4_gateway] = v4_gateway
				end
				interface.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update lxc start"
				LxcController.update_interfaces @config, interface.container
				@logger.debug "#{self.class}##{__method__}: " + "update lxc end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			interface
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_interface id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		interface = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				interface = Interface.find( id )
				interface.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update lxc start"
				LxcController.update_interfaces @config, interface.container
				@logger.debug "#{self.class}##{__method__}: " + "update lxc end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			interface
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def napts
		@logger.info "#{self.class}##{__method__}"
		Napt.all
	end

	def create_napt container_id, name, dport, sport: nil, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "container_id: #{container_id}, name: #{name}, dport: #{dport}, sport: #{sport}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		napt = nil
		lock_success = false
		update_db_success = false
		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				napt = Napt.new
				napt[:container_id] = container_id
				napt[:name]         = name
				napt[:sport]        = sport || napt.assign_sport( @config )
				napt[:dport]        = dport
				napt.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update iptables start"
				IptablesController.create @config, napt
				@logger.debug "#{self.class}##{__method__}: " + "update iptables end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			napt
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_napt id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		napt = nil
		lock_success = false
		update_db_success = false
		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				napt = Napt.find( id )
				napt.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update iptables start"
				IptablesController.destroy @config, napt
				@logger.debug "#{self.class}##{__method__}: " + "update iptables end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			napt
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def reverse_proxies
		@logger.info "#{self.class}##{__method__}"
		ReverseProxy.all
	end

	def create_reverse_proxy container_id, name, location, proxy_port, proxy_pass, listen_port: nil, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "container_id: #{container_id}, name: #{name}, location: #{location}, proxy_port: #{proxy_port}, proxy_pass: #{proxy_pass}, listen_port: #{listen_port}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		reverse_proxy = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				reverse_proxy = ReverseProxy.new
				reverse_proxy[:container_id] = container_id
				reverse_proxy[:name]         = name
				reverse_proxy[:listen_port]  = listen_port || reverse_proxy.assign_listen_port( @config )
				reverse_proxy[:location]     = location
				reverse_proxy[:proxy_port]   = proxy_port
				reverse_proxy[:proxy_pass]   = proxy_pass
				reverse_proxy.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update nginx config start"
				NginxController.create @config, reverse_proxy
				@logger.debug "#{self.class}##{__method__}: " + "update nginx config end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			reverse_proxy
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_reverse_proxy id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		reverse_proxy = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				reverse_proxy = ReverseProxy.find( id )
				reverse_proxy.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "update nginx config start"
				NginxController.destroy @config, reverse_proxy
				@logger.debug "#{self.class}##{__method__}: " + "update nginx config end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			reverse_proxy
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def snapshots
		@logger.info "#{self.class}##{__method__}"
		Snapshot.all
	end

	def create_snapshot container_id, name, description, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "container_id: #{container_id}, name: #{name}, description: #{description}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		snapshot = nil
		lock_success = false
		update_db_success = false
		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				snapshot = Snapshot.new
				snapshot[:container_id] = container_id
				snapshot[:name]         = name
				snapshot[:description]  = description
				snapshot.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "create snapshot start"
				ZfsController.create_snapshot @config, snapshot
				@logger.debug "#{self.class}##{__method__}: " + "create snapshot end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			snapshot
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def destroy_snapshot id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		snapshot = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				snapshot = Snapshot.find( id )
				snapshot.destroy!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "destroy snapshot start"
				ZfsController.destroy_snapshot @config, snapshot
				@logger.debug "#{self.class}##{__method__}: " + "destroy snapshot start"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			snapshot
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def edit_snapshot id, name, description, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}, name: #{name}, description: #{description}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		snapshot = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				snapshot = Snapshot.find( id )
				snapshot[:name]        = name
				snapshot[:description] = description
				snapshot.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			snapshot
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def rollback_snapshot id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "id: #{id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		snapshot = nil
		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "rollback snapshot start"
				snapshot = Snapshot.find( id )
				ZfsController.rollback_snapshot @config, snapshot
				@logger.debug "#{self.class}##{__method__}: " + "rollback snapshot end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			snapshot
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def clones
		@logger.info "#{self.class}##{__method__}"
		Clone.all
	end

	def create_clone snapshot_id, name, hostname, description, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "snapshot_id: #{snapshot_id}, name: #{name}, hostname: #{hostname}, description: #{description}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		container = nil
		management_interface = nil
		management_napt = nil
		other_interfaces = Array.new
		other_napts = Array.new
		other_reverse_proxies = Array.new
		lock_success = false
		update_db_success = false
		create_zfs_success = false
		exportfs_success = false
		create_management_interface_success = false
		create_management_napt_success = false
		create_other_interfaces_success = false
		create_other_napts_success = false
		create_other_reverse_proxies_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				snapshot = Snapshot.find( snapshot_id )
				clone = Clone.new
				clone[:snapshot_id] = snapshot.id
				clone.save!
				container = Container.new
				container[:name]        = name
				container[:hostname]    = hostname
				container[:description] = description
				container[:clone_id]    = clone.id
				container[:distro_id]   = Snapshot.find( snapshot_id ).container.distro_id
				container[:state]       = LxcManager::Container::STOPPED
				container.save!
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "create zfs start"
				ZfsController.create_clone @config, clone
				create_zfs_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create zfs end"

				@logger.debug "#{self.class}##{__method__}: " + "export lxc start"
				LxcController.exportfs @config, container
				exportfs_success = true
				@logger.debug "#{self.class}##{__method__}: " + "export lxcs end"

				@logger.debug "#{self.class}##{__method__}: " + "update lxc parameters start"
				LxcController.update_parameters @config, container
				@logger.debug "#{self.class}##{__method__}: " + "update lxc parameters end"

				@logger.debug "#{self.class}##{__method__}: " + "update lxc interfaces start"
				LxcController.update_interfaces @config, container
				@logger.debug "#{self.class}##{__method__}: " + "update lxc interfaces end"

				management_network = Network.find_by_name( 'management' )
				mng_nw_v4_gateway  = @config['management_network_bridge_v4_address']

				@logger.debug "#{self.class}##{__method__}: " + "create management interface start"
				management_interface = self.create_interface management_network.id, container.id, 'management', v4_gateway: mng_nw_v4_gateway, locked: true
				create_management_interface_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create management interface end"

				@logger.debug "#{self.class}##{__method__}: " + "create management napt start"
				management_napt      = self.create_napt container.id, 'management', '22', locked: true
				create_management_napt_success = true
				@logger.debug "#{self.class}##{__method__}: " + "create management napt end"

				@logger.debug "#{self.class}##{__method__}: " + "create other interfaces start"
				snapshot.container.interfaces.select{ |interface| interface.name != 'management' }.each{ |interface|
					other_interfaces.push self.create_interface interface.network.id, container.id, interface.name, interface.v4_address, locked: true
					create_other_interfaces_success = true
				}
				@logger.debug "#{self.class}##{__method__}: " + "create other interfaces end"

				@logger.debug "#{self.class}##{__method__}: " + "create other napts start"
				snapshot.container.napts.select{ |napt| napt.name != 'management' }.each{ |napt|
					other_napts.push self.create_napt container.id, napt.name, napt.dport, locked: true
					create_other_napts_success = true
				}
				@logger.debug "#{self.class}##{__method__}: " + "create other napts end"

				@logger.debug "#{self.class}##{__method__}: " + "create other reverse_proxies start"
				snapshot.container.reverse_proxies.each{ |reverse_proxy|
					other_reverse_proxies.push self.create_reverse_proxy container.id, reverse_proxy.name, reverse_proxy.location, reverse_proxy.proxy_port, reverse_proxy.proxy_pass, locked: true
					create_other_reverse_proxies_success = true
				}
				@logger.debug "#{self.class}##{__method__}: " + "create other reverse_proxies end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"

			container
		rescue
			if create_other_reverse_proxies_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy other reverse_proxies start"
				other_reverse_proxies.each{ |reverse_proxy|
					NginxController.destroy @config, reverse_proxy
				}
				@logger.debug "#{self.class}##{__method__}: " + "destroy other reverse_proxies end"
			end

			if create_other_napts_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy other napts start"
				other_napts.each{ |napt|
					IptablesController.destroy @config, napt
				}
				@logger.debug "#{self.class}##{__method__}: " + "destroy other napts end"
			end

			if create_other_interfaces_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy other interfaces start"
				other_interfaces.each{ |interface|
					LxcController.update_interfaces @config, container
				}
				@logger.debug "#{self.class}##{__method__}: " + "destroy other interfaces end"
			end

			if create_management_napt_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy management napt start"
				IptablesController.destroy @config, management_napt
				@logger.debug "#{self.class}##{__method__}: " + "destroy management napt end"
			end

			if create_management_interface_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy management interface start"
				LxcController.update_interfaces @config, container
				@logger.debug "#{self.class}##{__method__}: " + "destroy management interface end"
			end

			if exportfs_success
				@logger.debug "#{self.class}##{__method__}: " + "unexport lxc start"
				LxcController.unexportfs @config, container
				@logger.debug "#{self.class}##{__method__}: " + "unexport lxcs end"
			end

			if create_zfs_success
				@logger.debug "#{self.class}##{__method__}: " + "destroy zfs start"
				ZfsController.destroy @config, container
				@logger.debug "#{self.class}##{__method__}: " + "destroy zfs end"
			end

			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end

	def promote container_id, locked: false
		@logger.info "#{self.class}##{__method__}"
		@logger.debug "#{self.class}##{__method__}: " + "container_id: #{container_id}"
		@logger.debug "#{self.class}##{__method__}: " + "locked: #{locked}"

		lock_success = false
		update_db_success = false

		begin
			unless locked
				lock_success = @@m.try_lock
				@logger.debug "#{self.class}##{__method__}: " + "try_lock: #{lock_success}"
				unless lock_success
					raise "Couldn't get lock. Please try again later."
				end
			end

			@logger.debug "#{self.class}##{__method__}: " + "transaction start"
			ActiveRecord::Base.transaction do
				@logger.debug "#{self.class}##{__method__}: " + "update db start"
				clone = Container.find( container_id ).clone
				master_snapshot = Snapshot.find( clone.snapshot_id )
				master_container = Container.find( master_snapshot.container_id )
				master_snapshots = Snapshot.
					where( container_id: master_snapshot.container_id ).
					where( Snapshot.arel_table[:created_at].lteq master_snapshot.created_at )
				clone.container.update!( clone_id: master_container.clone_id )
				master_snapshots.each{ |master_snapshot|
					master_snapshot.update!( container_id: container_id )
				}
				master_container.update!( clone_id: clone.id )
				update_db_success = true
				@logger.debug "#{self.class}##{__method__}: " + "update db end"

				@logger.debug "#{self.class}##{__method__}: " + "zfs promote start"
				ZfsController.promote @config, clone.container
				@logger.debug "#{self.class}##{__method__}: " + "zfs promote end"
			end
			@logger.debug "#{self.class}##{__method__}: " + "transaction end"
		rescue
			raise
		ensure
			unless locked
				if lock_success
					@logger.debug "#{self.class}##{__method__}: " + "unlock start"
					@@m.unlock
					@logger.debug "#{self.class}##{__method__}: " + "unlock end"
				end
			end
		end
	end
end
