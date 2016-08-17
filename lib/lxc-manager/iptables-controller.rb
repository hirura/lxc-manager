# coding: utf-8

require_relative '../lxc-manager'

class LxcManager
	class IptablesController
		def self.create config, napt, interface
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "iptables -t nat -A PREROUTING -p tcp --dport #{napt.sport} -j DNAT --to #{interface.v4_address}:#{napt.dport}"
				if s.exit_status != 0
					raise "Failed: Add iptables rule"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.destroy config, napt, interface
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "iptables -t nat -D PREROUTING -p tcp --dport #{napt.sport} -j DNAT --to #{interface.v4_address}:#{napt.dport}"
				if s.exit_status != 0
					raise "Failed: Delete iptables rule"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.reset config, napts
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "netfilter-persistent reload"
				if s.exit_status != 0
					raise "Failed: Reload iptables rule"
				end

				napts.each{ |napt|
					interface = napt.container.interfaces.find_by_name( 'management' )

					ret = s.run "iptables -t nat -A PREROUTING -p tcp --dport #{napt.sport} -j DNAT --to #{interface.v4_address}:#{napt.dport}"
					if s.exit_status != 0
						raise "Failed: Add iptables rule"
					end
				}
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
