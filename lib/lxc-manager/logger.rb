require 'logger'
require 'singleton'

class LxcManager
	class Logger
		include Singleton

		def initialize
			log_file = File.join File.dirname( File.expand_path( __FILE__ ) ), '..', '..', 'log', 'lxc-manager.log'
			@logger = ::Logger.new log_file, 'daily'
			@logger.level = ::Logger::DEBUG
		end

		def method_missing method, *arg
			@logger.send method, *arg
		end
	end
end
