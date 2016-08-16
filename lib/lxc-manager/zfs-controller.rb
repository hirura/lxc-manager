# coding: utf-8

require_relative '../lxc-manager'

class LxcManager
	class ZfsController
		def self.create config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = "#{config['zfs_pool_lxc_path']}/#{container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs create -o compression=lz4 #{path}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't create #{path}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.destroy config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = "#{config['zfs_pool_lxc_path']}/#{container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs destroy #{path}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't destroy #{path}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.create_snapshot config, snapshot
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = "#{config['zfs_pool_lxc_path']}/#{snapshot.container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs snapshot #{path}@#{snapshot.id}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't take snapshot #{path}@#{snapshot.id}}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.rollback_snapshot config, snapshot
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = "#{config['zfs_pool_lxc_path']}/#{snapshot.container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs rollback #{path}@#{snapshot.id}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't rollback snapshot #{path}@#{snapshot.id}}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.destroy_snapshot config, snapshot
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = "#{config['zfs_pool_lxc_path']}/#{snapshot.container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs destroy #{path}@#{snapshot.id}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't destroy snapshot #{path}@#{snapshot.id}}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.create_clone config, clone
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			snapshot_path = "#{config['zfs_pool_lxc_path']}/#{clone.snapshot.container.id}@#{clone.snapshot.id}"
			container_path = "#{config['zfs_pool_lxc_path']}/#{clone.container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs clone #{snapshot_path} #{container_path}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't clone #{snapshot_path} #{container_path}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.promote config, clone_container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			clone_container_path = "#{config['zfs_pool_lxc_path']}/#{clone_container.id}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				ret = s.run "zfs promote #{clone_container_path}"
				if s.exit_status != 0
					raise "Failed: ZFS: couldn't promote #{clone_container_path}: #{ret}"
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
