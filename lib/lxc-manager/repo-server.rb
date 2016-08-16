# coding: utf-8

require 'uri'
require 'webrick'

require_relative '../lxc-manager'

class LxcManager
	class RepoServer
		def initialize
			logger = LxcManager::Logger.instance
			config  = YAML.load_file( LxcManager::CONFIG_FILE_PATH )
			repo_url = URI.parse( config['repo_url'] )
			distro_pool_dir = config['dir_pool_distro_path']
			@srv = WEBrick::HTTPServer.new( {
				BindAddress:         repo_url.host,
				Port:                repo_url.port,
				DoNotReverseLookup:  true,
				DocumentRoot:        distro_pool_dir,
				DocumentRootOptions: { FancyIndexing: false },
				Logger:              logger,
				AccessLog:           [[logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT]],
			} )

			[:INT, :TERM].each do |signal|
				Signal.trap( signal ) do
					@srv.shutdown
				end
			end
		end

		def start
			@srv.start
		end
	end
end

if $0 == __FILE__
	LxcManager::RepoServer.start
end
