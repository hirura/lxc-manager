# coding: utf-8

require 'bundler/setup'

require_relative '../lxc-manager'

class LxcManager
	class HostResourceMonitor
		def self.get_resource config, host
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			result = Hash.new

			target = Hash.new
			target[:address] = host.v4_address
			target[:port] = '22'
			target[:user] = 'root'
			target[:auth] = :none
			target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				s.jump( :ssh, target: target )

				result['cpu_idle'] = s.run "sar -u 1 1 | grep Average: | awk -F' ' '{print $8}'"
				result['mem_total'] = s.run "free | grep Mem: | awk -F' ' '{print $2}'"
				result['mem_used']  = s.run "free | grep Mem: | awk -F' ' '{print $3}'"
				result['swap_total'] = s.run "free | grep Swap: | awk -F' ' '{print $2}'"
				result['swap_used']  = s.run "free | grep Swap: | awk -F' ' '{print $3}'"

				s.jump( :exit )
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"

			result
		end
	end
end
