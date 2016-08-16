# coding: utf-8

require_relative '../lxc-manager'

class LxcManager
	class NetworkController
		def self.create config, network, hosts
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			nw_if = config['internal_network_interface']
			nw_id = network.id
			vlan_id = network.vlan_id
			vlan_if = "#{nw_if}.#{vlan_id}"
			bridge_if = "br#{nw_id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				begin
					ret = s.run "ip link add link #{nw_if} name #{vlan_if} type vlan id #{vlan_id}"
					ret = s.run "ip link set dev #{vlan_if} up"
					ret = s.run "ip link add name #{bridge_if} type bridge"
					ret = s.run "ip link set dev #{bridge_if} up"
					ret = s.run "ip link set dev #{vlan_if} master #{bridge_if}"
					if network.host_v4_address
						ret = s.run "ip addr add #{network.host_v4_address}/#{network.v4_prefix} dev #{bridge_if}"
					end

					hosts.each{ |host|
						target = Hash.new
						target[:address] = host.v4_address
						target[:port] = '22'
						target[:user] = 'root'
						target[:auth] = :none
						target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

						s.jump( :ssh, target: target )

						ret = s.run "ip link add link #{nw_if} name #{vlan_if} type vlan id #{vlan_id}"
						ret = s.run "ip link set dev #{vlan_if} up"
						ret = s.run "ip link add name #{bridge_if} type bridge"
						ret = s.run "ip link set dev #{bridge_if} up"
						ret = s.run "ip link set dev #{vlan_if} master #{bridge_if}"

						s.jump( :exit )
					}
				rescue => e
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.destroy config, network, hosts
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			nw_if = config['internal_network_interface']
			nw_id = network.id
			vlan_id = network.vlan_id
			vlan_if = "#{nw_if}.#{vlan_id}"
			bridge_if = "br#{nw_id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				begin
					ret = s.run "ip link del dev #{bridge_if}"
					ret = s.run "ip link del dev #{vlan_if}"

					hosts.each{ |host|
						target = Hash.new
						target[:address] = host.v4_address
						target[:port] = '22'
						target[:user] = 'root'
						target[:auth] = :none
						target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

						s.jump( :ssh, target: target )

						ret = s.run "ip link del dev #{bridge_if}"
						ret = s.run "ip link del dev #{vlan_if}"

						s.jump( :exit )
					}
				rescue => e
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.configure_host config, network, host
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			nw_if = config['internal_network_interface']
			nw_id = network.id
			vlan_id = network.vlan_id
			vlan_if = "#{nw_if}.#{vlan_id}"
			bridge_if = "br#{nw_id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				begin
					ret = s.run "ip link add link #{nw_if} name #{vlan_if} type vlan id #{vlan_id}"
					ret = s.run "ip link set dev #{vlan_if} up"
					ret = s.run "ip link add name #{bridge_if} type bridge"
					ret = s.run "ip link set dev #{bridge_if} up"
					ret = s.run "ip link set dev #{vlan_if} master #{bridge_if}"
					if network.host_v4_address
						ret = s.run "ip addr add #{network.host_v4_address}/#{network.v4_prefix} dev #{bridge_if}"
					end

					target = Hash.new
					target[:address] = host.v4_address
					target[:port] = '22'
					target[:user] = 'root'
					target[:auth] = :none
					target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

					s.jump( :ssh, target: target )

					ret = s.run "ip link add link #{nw_if} name #{vlan_if} type vlan id #{vlan_id}"
					ret = s.run "ip link set dev #{vlan_if} up"
					ret = s.run "ip link add name #{bridge_if} type bridge"
					ret = s.run "ip link set dev #{bridge_if} up"
					ret = s.run "ip link set dev #{vlan_if} master #{bridge_if}"

					s.jump( :exit )
				rescue => e
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.configure_all_hosts config, network, hosts
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			nw_if = config['internal_network_interface']
			nw_id = network.id
			vlan_id = network.vlan_id
			vlan_if = "#{nw_if}.#{vlan_id}"
			bridge_if = "br#{nw_id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				begin
					ret = s.run "ip link add link #{nw_if} name #{vlan_if} type vlan id #{vlan_id}"
					ret = s.run "ip link set dev #{vlan_if} up"
					ret = s.run "ip link add name #{bridge_if} type bridge"
					ret = s.run "ip link set dev #{bridge_if} up"
					ret = s.run "ip link set dev #{vlan_if} master #{bridge_if}"
					if network.host_v4_address
						ret = s.run "ip addr add #{network.host_v4_address}/#{network.v4_prefix} dev #{bridge_if}"
					end

					hosts.each{ |host|
						target = Hash.new
						target[:address] = host.v4_address
						target[:port] = '22'
						target[:user] = 'root'
						target[:auth] = :none
						target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

						s.jump( :ssh, target: target )

						ret = s.run "ip link add link #{nw_if} name #{vlan_if} type vlan id #{vlan_id}"
						ret = s.run "ip link set dev #{vlan_if} up"
						ret = s.run "ip link add name #{bridge_if} type bridge"
						ret = s.run "ip link set dev #{bridge_if} up"
						ret = s.run "ip link set dev #{vlan_if} master #{bridge_if}"

						s.jump( :exit )
					}
				rescue => e
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
