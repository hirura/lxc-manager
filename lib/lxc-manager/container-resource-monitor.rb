# coding: utf-8

require 'bundler/setup'

require_relative '../lxc-manager'

class LxcManager
	class ContainerResourceMonitor
		def self.get_resource config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			dir_mount_lxc_path = config['dir_mount_lxc_path']

			result = Hash.new

			target = Hash.new
			target[:address] = container.host.v4_address
			target[:port] = '22'
			target[:user] = 'root'
			target[:auth] = :none
			target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				s.jump( :ssh, target: target )

				ret = s.run "lxc-info -n #{container.id} -P #{dir_mount_lxc_path}"
				result['cpu']         = ret.match(/CPU use: +(.+)/).to_a.last
				result['blkio']       = ret.match(/BlkIO use: +(.+)/).to_a.last
				result['memory']      = ret.match(/Memory use: +(.+)/).to_a.last
				result['tx_bytes']    = ret.match(/ TX bytes: +(.+)/).to_a.last
				result['rx_bytes']    = ret.match(/ RX bytes: +(.+)/).to_a.last
				result['total_bytes'] = ret.match(/ Total bytes: +(.+)/).to_a.last

				s.jump( :exit )
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"

			result
		end
	end
end
