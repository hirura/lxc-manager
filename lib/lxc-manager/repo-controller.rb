# coding: utf-8

require_relative '../lxc-manager'

class LxcManager
	class RepoController
		def self.create config, distro
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			dir_pool_iso_path      = config['dir_pool_iso_path']
			dir_pool_distro_path   = config['dir_pool_distro_path']
			dir_export_distro_path = config['dir_export_distro_path']
			pool_iso_path      = File.join( dir_pool_iso_path, distro.iso )
			pool_distro_path   = File.join( dir_pool_distro_path, distro.id.to_s )
			export_distro_path = File.join( dir_export_distro_path, distro.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				mkdir_pool_distro_success = false
				mount_pool_distro_success = false
				mkdir_export_distro_success = false
				mount_export_distro_success = false
				export_export_distro_success = false

				begin
					ret = s.run "mkdir -p #{pool_distro_path}"
					if s.exit_status == 0
						mkdir_pool_distro_success = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{pool_distro_path}"
					end

					ret = s.run "mountpoint -q #{pool_distro_path}"
					if s.exit_status != 0
						ret = s.run "mount -o loop,ro #{pool_iso_path} #{pool_distro_path}"
						if s.exit_status == 0
							mount_pool_distro_success = true
						else
							raise "Failed: Mount: couldn't mount #{pool_iso_path} to #{pool_distro_path}"
						end
					else
						mount_pool_distro_success = true
					end

					ret = s.run "mkdir -p #{export_distro_path}"
					if s.exit_status == 0
						mkdir_export_distro_success = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{export_distro_path}"
					end

					ret = s.run "mountpoint -q #{export_distro_path}"
					if s.exit_status != 0
						ret = s.run "mount --bind #{pool_distro_path} #{export_distro_path}"
						if s.exit_status == 0
							mount_export_distro_success = true
						else
							raise "Failed: Mount: couldn't mount #{pool_distro_path} to #{export_distro_path}"
						end
					else
						mount_export_distro_success = true
					end

					ret = s.run "exportfs -o rw,no_root_squash,no_subtree_check,nohide #{allowed_clients}:#{export_distro_path}"
					if s.exit_status == 0
						export_export_distro_success = true
					else
						raise "Failed: Export: couldn't export #{allowed_clients}:#{export_distro_path}"
					end
				rescue => e
					if mount_export_distro_success
						ret = s.run "umount -l #{export_distro_path}"
					end

					if mkdir_export_distro_success
						ret = s.run "rmdir #{export_distro_path}"
					end

					if mount_pool_distro_success
						ret = s.run "umount -l #{pool_distro_path}"
					end

					if mkdir_pool_distro_success
						ret = s.run "rmdir #{pool_distro_path}"
					end

					raise
				end
			}
		end

		def self.destroy config, distro
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			dir_pool_iso_path      = config['dir_pool_iso_path']
			dir_pool_distro_path   = config['dir_pool_distro_path']
			dir_export_distro_path = config['dir_export_distro_path']
			pool_iso_path      = File.join( dir_pool_iso_path, distro.iso )
			pool_distro_path   = File.join( dir_pool_distro_path, distro.id.to_s )
			export_distro_path = File.join( dir_export_distro_path, distro.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				unexport_export_distro_success = false
				umount_export_distro_success = false
				rmdir_export_distro_success = false
				umount_pool_distro_success = false
				rmdir_pool_distro_success = false

				begin
					ret = s.run "exportfs -u #{allowed_clients}:#{export_distro_path}"
					if s.exit_status == 0
						unexport_export_distro_success = true
					else
						raise "Failed: Unexport: couldn't unexport #{allowed_clients}:#{export_distro_path}"
					end

					ret = s.run "mkdir -p #{export_distro_path}"
					ret = s.run "mountpoint -q #{export_distro_path}"
					if s.exit_status == 0
						ret = s.run "umount -l #{export_distro_path}"
						if s.exit_status == 0
							umount_export_distro_success = true
						else
							raise "Failed: Umount: couldn't umount #{export_distro_path}"
						end
					else
						umount_export_distro_success = true
					end

					ret = s.run "rmdir #{export_distro_path}"
					if s.exit_status == 0
						rmdir_export_distro_success = true
					else
						raise "Failed: Rmdir: couldn't rmdir #{export_distro_path}"
					end

					ret = s.run "mkdir -p #{pool_distro_path}"
					ret = s.run "mountpoint -q #{pool_distro_path}"
					if s.exit_status == 0
						ret = s.run "umount -l #{pool_distro_path}"
						if s.exit_status == 0
							umount_pool_distro_success = true
						else
							raise "Failed: Umount: couldn't umount #{pool_distro_path}"
						end
					else
						umount_pool_distro_success = true
					end

					ret = s.run "rmdir #{pool_distro_path}"
					if s.exit_status == 0
						rmdir_pool_distro_success = true
					else
						raise "Failed: Rmdir: couldn't rmdir #{pool_distro_path}"
					end
				rescue => e
					raise
				end
			}
		end

		def self.reconfigure config, distros
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			dir_pool_iso_path      = config['dir_pool_iso_path']
			dir_pool_distro_path   = config['dir_pool_distro_path']
			dir_export_distro_path = config['dir_export_distro_path']

			distros.each{ |distro|
				pool_iso_path      = File.join( dir_pool_iso_path, distro.iso )
				pool_distro_path   = File.join( dir_pool_distro_path, distro.id.to_s )
				export_distro_path = File.join( dir_export_distro_path, distro.id.to_s )

				allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

				logger.debug "#{self}##{__method__}: " + "cli-agent start"
				CliAgent.open( config['local_shell'] ){ |s|
					mkdir_pool_distro_success = false
					mount_pool_distro_success = false
					mkdir_export_distro_success = false
					mount_export_distro_success = false
					export_export_distro_success = false

					begin
						ret = s.run "mkdir -p #{pool_distro_path}"
						if s.exit_status == 0
							mkdir_pool_distro_success = true
						else
							raise "Failed: mkdir -p: couldn't mkdir -p #{pool_distro_path}"
						end

						ret = s.run "mountpoint -q #{pool_distro_path}"
						if s.exit_status != 0
							ret = s.run "mount -o loop,ro #{pool_iso_path} #{pool_distro_path}"
							if s.exit_status == 0
								mount_pool_distro_success = true
							else
								raise "Failed: Mount: couldn't mount #{pool_iso_path} to #{pool_distro_path}"
							end
						else
							mount_pool_distro_success = true
						end

						ret = s.run "mkdir -p #{export_distro_path}"
						if s.exit_status == 0
							mkdir_export_distro_success = true
						else
							raise "Failed: mkdir -p: couldn't mkdir -p #{export_distro_path}"
						end

						ret = s.run "mountpoint -q #{export_distro_path}"
						if s.exit_status != 0
							ret = s.run "mount --bind #{pool_distro_path} #{export_distro_path}"
							if s.exit_status == 0
								mount_export_distro_success = true
							else
								raise "Failed: Mount: couldn't mount #{pool_distro_path} to #{export_distro_path}"
							end
						else
							mount_export_distro_success = true
						end

						ret = s.run "exportfs -o rw,no_root_squash,no_subtree_check,nohide #{allowed_clients}:#{export_distro_path}"
						if s.exit_status == 0
							export_export_distro_success = true
						else
							raise "Failed: Export: couldn't export #{allowed_clients}:#{export_distro_path}"
						end
					rescue => e
						if mount_export_distro_success
							ret = s.run "umount -l #{export_distro_path}"
						end

						if mkdir_export_distro_success
							ret = s.run "rmdir #{export_distro_path}"
						end

						if mount_pool_distro_success
							ret = s.run "umount -l #{pool_distro_path}"
						end

						if mkdir_pool_distro_success
							ret = s.run "rmdir #{pool_distro_path}"
						end

						raise
					end
				}
			}
		end
	end
end
