# coding: utf-8

require 'bundler/setup'

require_relative '../lxc-manager'

class LxcManager
	class StorageResourceMonitor
		def self.get_resource config
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			result = Hash.new

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				result['size']      = s.run "zpool get -pH size ext | awk -F' ' '{print $3}'"
				result['allocated'] = s.run "zpool get -pH allocated ext | awk -F' ' '{print $3}'"
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"

			result
		end
	end
end
