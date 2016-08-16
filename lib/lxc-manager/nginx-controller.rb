# coding: utf-8

require 'fileutils'

require_relative '../lxc-manager'

class LxcManager
	class NginxController
		def self.create config, reverse_proxy
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			reverse_proxy_config_file = "#{config['nginx_conf_dir']}/#{reverse_proxy.id}.conf"

			nginx_config = ""
			nginx_config += "server {"
			nginx_config += "  listen #{reverse_proxy.listen_port};"
			nginx_config += "  server_name _;"
			nginx_config += "  proxy_set_header Host $http_host;"
			nginx_config += "  location #{reverse_proxy.location} {"
			nginx_config += "    proxy_pass http://#{reverse_proxy.container.interfaces.find_by_name( 'management' ).v4_address}:#{reverse_proxy.proxy_port}#{reverse_proxy.proxy_pass};"
			nginx_config += "  }"
			nginx_config += "}"
			logger.debug "#{self}##{__method__}: " + "create nginx conf file:\n#{nginx_config}"
			File.open( reverse_proxy_config_file, 'w' ){ |fo|
				fo.puts nginx_config
			}

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				reload_nginx_success = false

				begin
					ret = s.run "systemctl reload nginx"
					if s.exit_status == 0
						reload_nginx_success = true
					else
						raise "Failed: reload nginx"
					end
				rescue
					FileUtils.rm( reverse_proxy_config_file, force: true )
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.destroy config, reverse_proxy
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			reverse_proxy_config_file = "#{config['nginx_conf_dir']}/#{reverse_proxy.id}.conf"

			logger.debug "#{self}##{__method__}: " + "remove #{reverse_proxy_config_file}"
			FileUtils.rm( reverse_proxy_config_file, force: true )

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "systemctl reload nginx"
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
