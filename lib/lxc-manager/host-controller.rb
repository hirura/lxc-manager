# coding: utf-8

require_relative '../lxc-manager'

class LxcManager
	class HostController
		def self.configure config, host
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			dir_mount_path    = config['dir_mount_path']
			dir_root_dev_path = config['dir_root_dev_path']
			server_v4_address   = config['inter_host_network_interface_v4_address']

			target = Hash.new
			target[:address] = host.v4_address
			target[:port] = '22'
			target[:user] = 'root'
			target[:auth] = :none
			target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				jump_success = false
				mkdir_mount_path = false
				mkdir_root_dev_path = false
				mount_success = false

				begin
					s.jump( :ssh, target: target )
					jump_success = true

					ret = s.run "mkdir -p #{dir_mount_path}"
					if s.exit_status == 0
						mkdir_mount_path = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{dir_mount_path}"
					end

					ret = s.run "mkdir -p #{dir_root_dev_path}"
					if s.exit_status == 0
						mkdir_root_dev_path = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{dir_root_dev_path}"
					end

					ret = s.run "mountpoint -q #{dir_mount_path}"
					if s.exit_status != 0
						ret = s.run "mount -t nfs #{server_v4_address}:/ #{dir_mount_path}"
						if s.exit_status == 0
							mount_success = true
						else
							raise "Failed: Mount: couldn't mount #{pool_lxc_path} to #{dir_mount_path}"
						end
					else
						mount_success = true
					end

					s.jump( :exit )
				rescue => e
					if mkdir_root_dev_path
					end

					if mkdir_mount_path
					end

					if jump_success
						s.jump( :exit )
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
