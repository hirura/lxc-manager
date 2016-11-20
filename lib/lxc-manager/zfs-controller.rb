# coding: utf-8

require_relative '../lxc-manager'

class LxcManager
	class ZfsController
		def self.create config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = if container.storage_type == LxcManager::Container::StorageType::NFS
				       "#{config['zfs_pool_lxc_path']}/#{container.id}"
			       elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
				       "#{config['zfs_pool_zvol_path']}/#{container.id}"
			       end

			options = if container.storage_type == LxcManager::Container::StorageType::NFS
					  "-o compression=lz4"
				  elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
					  "-o compression=lz4 -o sync=disabled -s -b 4096 -V #{container.size_gb}G"
				  end

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			LxcManager::CliAgent.open( config['local_shell'] ){ |s|
				zfs_create_success = false
				mkfs_success = false

				begin
					ret = s.run "zfs create #{options} #{path}"
					if s.exit_status != 0
						raise "Failed: ZFS: couldn't create #{path}: #{ret}"
					else
						zfs_create_success = true
					end

					if container.storage_type == LxcManager::Container::StorageType::NFS
						ret = s.run "mkfs -t xfs -s size=4096 /dev/zvol/#{path}"
						if s.exit_status != 0
							raise "Failed: Mkfs: couldn't mkfs /dev/zvol/#{path}: #{ret}"
						else
							mkfs_success = true
						end
					end
				rescue => e
					if zfs_create_success
						ret = s.run "zfs destroy #{path}"
						if s.exit_status != 0
							raise "Failed: ZFS: couldn't destroy #{path}: #{ret}"
						end
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.destroy config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if  LxcManager::DRY_RUN

			path = if container.storage_type == LxcManager::Container::StorageType::NFS
				       "#{config['zfs_pool_lxc_path']}/#{container.id}"
			       elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
				       "#{config['zfs_pool_zvol_path']}/#{container.id}"
			       end

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

			path = if container.storage_type == LxcManager::Container::StorageType::NFS
				       "#{config['zfs_pool_lxc_path']}/#{container.id}"
			       elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
				       "#{config['zfs_pool_zvol_path']}/#{container.id}"
			       end

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

			path = if container.storage_type == LxcManager::Container::StorageType::NFS
				       "#{config['zfs_pool_lxc_path']}/#{container.id}"
			       elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
				       "#{config['zfs_pool_zvol_path']}/#{container.id}"
			       end

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

			path = if container.storage_type == LxcManager::Container::StorageType::NFS
				       "#{config['zfs_pool_lxc_path']}/#{container.id}"
			       elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
				       "#{config['zfs_pool_zvol_path']}/#{container.id}"
			       end

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

			snapshot_path = if container.storage_type == LxcManager::Container::StorageType::NFS
						"#{config['zfs_pool_lxc_path']}/#{clone.snapshot.container.id}@#{clone.snapshot.id}"
					elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
						"#{config['zfs_pool_zvol_path']}/#{clone.snapshot.container.id}@#{clone.snapshot.id}"
					end
			container_path = if container.storage_type == LxcManager::Container::StorageType::NFS
						 "#{config['zfs_pool_lxc_path']}/#{clone.container.id}"
					 elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
						 "#{config['zfs_pool_zvol_path']}/#{clone.container.id}"
					 end

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

			clone_container_path = if container.storage_type == LxcManager::Container::StorageType::NFS
						       "#{config['zfs_pool_lxc_path']}/#{clone_container.id}"
					       elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
						       "#{config['zfs_pool_zvol_path']}/#{clone_container.id}"
					       end

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
