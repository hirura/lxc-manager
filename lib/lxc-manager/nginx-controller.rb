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
			nginx_config += "server {\n"
			nginx_config += "  listen #{reverse_proxy.listen_port};\n"
			nginx_config += "  server_name _;\n"
			nginx_config += "  proxy_set_header Host $http_host;\n"
			nginx_config += "  location #{reverse_proxy.location} {\n"
			nginx_config += "    proxy_pass http://#{reverse_proxy.container.interfaces.find_by_name( 'management' ).v4_address}:#{reverse_proxy.proxy_port}#{reverse_proxy.proxy_pass};\n"
			nginx_config += "    proxy_http_version 1.1;\n"
			nginx_config += "    proxy_set_header Upgrade $http_upgrade;\n"
			nginx_config += "    proxy_set_header Connection \"upgrade\";\n"
			if reverse_proxy.reverse_proxy_substitutes.any?
				nginx_config += "    sub_filter_types '*';\n"
				nginx_config += "    sub_filter_once off;\n"
				reverse_proxy.reverse_proxy_substitutes.each{ |reverse_proxy_substitute|
					nginx_config += "    sub_filter \"#{reverse_proxy_substitute.pattern}\" \"#{reverse_proxy_substitute.replacement}\";\n"
				}
			end
			nginx_config += "  }\n"
			nginx_config += "}\n"
			logger.debug "#{self}##{__method__}: " + "create nginx conf file: #{nginx_config}"
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
						raise "Failed: reload nginx: #{ret}"
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

			nginx_config = File.open( reverse_proxy_config_file ).read rescue ''

			logger.debug "#{self}##{__method__}: " + "remove #{reverse_proxy_config_file}"
			FileUtils.rm( reverse_proxy_config_file, force: true )

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				reload_nginx_success = false

				begin
					ret = s.run "systemctl reload nginx"
					if s.exit_status == 0
						reload_nginx_success = true
					else
						raise "Failed: reload nginx: #{ret}"
					end
				rescue
					logger.debug "#{self}##{__method__}: " + "create nginx conf file: #{nginx_config}"
					File.open( reverse_proxy_config_file, 'w' ){ |fo|
						fo.puts nginx_config
					}

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.replace config, reverse_proxy
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			reverse_proxy_config_file = "#{config['nginx_conf_dir']}/#{reverse_proxy.id}.conf"
			reverse_proxy_config_backup_file = "#{config['nginx_conf_dir']}/#{reverse_proxy.id}.conf.bak"

			logger.debug "#{self}##{__method__}: " + "copy #{reverse_proxy_config_file} to #{reverse_proxy_config_backup_file}"
			FileUtils.copy( reverse_proxy_config_file, reverse_proxy_config_backup_file, preserve: true )

			begin
				nginx_config = ""
				nginx_config += "server {\n"
				nginx_config += "  listen #{reverse_proxy.listen_port};\n"
				nginx_config += "  server_name _;\n"
				nginx_config += "  proxy_set_header Host $http_host;\n"
				nginx_config += "  location #{reverse_proxy.location} {\n"
				nginx_config += "    proxy_pass http://#{reverse_proxy.container.interfaces.find_by_name( 'management' ).v4_address}:#{reverse_proxy.proxy_port}#{reverse_proxy.proxy_pass};\n"
				nginx_config += "    proxy_http_version 1.1;\n"
				nginx_config += "    proxy_set_header Upgrade $http_upgrade;\n"
				nginx_config += "    proxy_set_header Connection \"upgrade\";\n"
				if reverse_proxy.reverse_proxy_substitutes.any?
					nginx_config += "    sub_filter_types '*';\n"
					nginx_config += "    sub_filter_once off;\n"
					reverse_proxy.reverse_proxy_substitutes.each{ |reverse_proxy_substitute|
						nginx_config += "    sub_filter \"#{reverse_proxy_substitute.pattern}\" \"#{reverse_proxy_substitute.replacement}\";\n"
					}
				end
				nginx_config += "  }\n"
				nginx_config += "}\n"
				logger.debug "#{self}##{__method__}: " + "create nginx conf file: #{nginx_config}"
				File.open( reverse_proxy_config_file, 'w' ){ |fo|
					fo.puts nginx_config
				}
			rescue
				logger.debug "#{self}##{__method__}: " + "move #{reverse_proxy_config_backup_file} to #{reverse_proxy_config_file}"
				FileUtils.move( reverse_proxy_config_backup_file, reverse_proxy_config_file, force: true )

				raise
			end

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				reload_nginx_success = false

				begin
					ret = s.run "systemctl reload nginx"
					if s.exit_status == 0
						reload_nginx_success = true
					else
						raise "Failed: reload nginx: #{ret}"
					end

					logger.debug "#{self}##{__method__}: " + "remove #{reverse_proxy_config_backup_file}"
					FileUtils.rm( reverse_proxy_config_backup_file, force: true )
				rescue
					logger.debug "#{self}##{__method__}: " + "move #{reverse_proxy_config_backup_file} to #{reverse_proxy_config_file}"
					FileUtils.move( reverse_proxy_config_backup_file, reverse_proxy_config_file, force: true )

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
