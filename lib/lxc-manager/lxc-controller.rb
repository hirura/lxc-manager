# coding: utf-8

require 'fileutils'

require_relative '../lxc-manager'

class LxcManager
	class LxcController
		def self.create config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				mkdir_export_lxc_success = false
				mount_success = false
				export_success = false
				mkdir_export_share_success = false
				mount_share_success = false
				export_share_success = false

				begin
					ret = s.run "rm -rf /var/cache/lxc"
					if s.exit_status != 0
						raise "Failed: rm -rf /var/cache/lxc: couldn't remove /var/cache/lxc"
					end

					ret = s.run "lxc-create -n #{container.id} -t #{template} -P #{dir_pool_lxc_path} -- --repo=#{repo_url}"
					if s.exit_status != 0
						raise "Failed: lxc-create: couldn't create #{container.name}"
					end

					ret = s.run "cat /usr/share/lxc/config/centos.common.conf | tee -a #{pool_lxc_path}/config"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{pool_lxc_path}/config"
					end

					ret = s.run "echo 'lxc.cgroup.devices.allow = b 7:* rwm' | tee -a #{pool_lxc_path}/config"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{pool_lxc_path}/config"
					end

					ret = s.run "echo 'lxc.mount.entry = #{root_dev_path} dev none bind,create=dir 0 0' | tee -a #{pool_lxc_path}/config"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{pool_lxc_path}/config"
					end

					ret = s.run "echo 'lxc.mount.entry = #{mount_distro_path} media/cdrom none bind,create=dir 0 0' | tee -a #{pool_lxc_path}/config"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{pool_lxc_path}/config"
					end

					ret = s.run "echo 'lxc.mount.entry = #{dir_mount_share_path} share none bind,create=dir 0 0' | tee -a #{pool_lxc_path}/config"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{pool_lxc_path}/config"
					end

					ret = s.run "sed -i -e '/^lxc.network*/d' #{pool_lxc_path}/config"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{pool_lxc_path}/config"
					end

					ret = s.run "echo 'function shutdown () { echo Sorry, shutdown command is not allowed.; }' | tee -a #{pool_lxc_path}/rootfs/root/.bashrc"
					if s.exit_status != 0
						raise "Failed: Edit /root/.bashrc: couldn't edit #{pool_lxc_path}/config/root/.bashrc"
					end

					ret = s.run "echo 'function reboot () { echo Sorry, reboot command is not allowed.; }' | tee -a #{pool_lxc_path}/rootfs/root/.bashrc"
					if s.exit_status != 0
						raise "Failed: Edit /root/.bashrc: couldn't edit #{pool_lxc_path}/config/root/.bashrc"
					end

					ret = s.run "sed -i -E 's/^[#]?PermitRootLogin .*$/PermitRootLogin yes/' #{pool_lxc_path}/rootfs/etc/ssh/sshd_config"
					if s.exit_status != 0
						raise "Failed: Edit /etc/ssh/sshd_config: couldn't edit #{pool_lxc_path}/rootfs/etc/ssh/sshd_config"
					end

					ret = s.run "echo 'root:rootroot' | chroot #{pool_lxc_path}/rootfs/ chpasswd"
					if s.exit_status != 0
						raise "Failed: Change Password: couldn't change root's password"
					end
				rescue => e
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.start config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			zfs_pool_zvol_path    = config['zfs_pool_zvol_path']
			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_zvol_path    = File.join( "/dev/zvol", zfs_pool_zvol_path, container.id.to_s )
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			inter_host_network_interface_v4_address = "#{config['inter_host_network_interface_v4_address']}"
			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			target = Hash.new
			target[:address] = container.host.v4_address
			target[:port] = '22'
			target[:user] = 'root'
			target[:auth] = :none
			target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				targetcli_ls_success = false
				targetcli_create_iblock_success = false
				targetcli_create_iscsi_success = false
				targetcli_set_attribute_success = false
				targetcli_create_luns_success = false
				targetcli_create_portals_success = false
				targetcli_create_acls_success = false
				jump_success = false
				mkdir_root_dev_success = false
				make_dev_files_success = false
				iscsiadm_discovery_success = false
				iscsiadm_node_success = false
				iscsiadm_node_login_success = false
				iscsiadm_session_success = false
				mkdir_mount_lxc_path_success = false
				mount_success = false
				lxc_start_success = false

				begin
					if container.storage_type == LxcManager::Container::StorageType::ISCSI
						ret = s.run "targetcli ls /"
						if s.exit_status == 0
							targetcli_ls_success = true
						else
							raise "Failed: targetcli ls: #{ret}"
						end

						ret = s.run "targetcli /backstores/iblock create name=#{container.id.to_s} dev=#{pool_zvol_path}"
						if s.exit_status == 0
							targetcli_create_iblock_success = true
						else
							raise "Failed: targetcli create iblock: #{ret}"
						end

						ret = s.run "targetcli /iscsi create iqn.2016-11.com.example:#{container.id.to_s}"
						if s.exit_status == 0
							targetcli_create_iscsi_success = true
						else
							raise "Failed: targetcli create iscsi: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1 set attribute authentication=0"
						if s.exit_status == 0
							targetcli_set_attribute_success = true
						else
							raise "Failed: targetcli set attribute: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/luns create /backstores/iblock/#{container.id.to_s}"
						if s.exit_status == 0
							targetcli_create_luns_success = true
						else
							raise "Failed: targetcli create luns: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/portals create #{inter_host_network_interface_v4_address} 3260"
						if s.exit_status == 0
							targetcli_create_portals_success = true
						else
							raise "Failed: targetcli create portals: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/acls create iqn.2016-11.com.example:#{container.host.name}"
						if s.exit_status == 0
							targetcli_create_acls_success = true
						else
							raise "Failed: targetcli create acls: #{ret}"
						end
					end

					s.jump( :ssh, target: target )
					jump_success = true

					if container.storage_type == LxcManager::Container::StorageType::NFS
						ret = s.run "mkdir -p #{root_dev_path}"
						if s.exit_status == 0
							mkdir_root_dev_success = true
						else
							raise "Failed: mkdir -p: couldn't mkdir -p #{root_dev_path}"
						end

						command = Array.new
						command.push "mknod -m 666  #{root_dev_path}/null c 1 3"
						command.push "mknod -m 666  #{root_dev_path}/zero c 1 5"
						command.push "mknod -m 666  #{root_dev_path}/random c 1 8"
						command.push "mknod -m 666  #{root_dev_path}/urandom c 1 9"
						command.push "mkdir -m 755  #{root_dev_path}/pts"
						command.push "mkdir -m 1777 #{root_dev_path}/shm"
						command.push "mknod -m 666  #{root_dev_path}/tty c 5 0"
						command.push "mknod -m 666  #{root_dev_path}/tty0 c 4 0"
						command.push "mknod -m 666  #{root_dev_path}/tty1 c 4 1"
						command.push "mknod -m 666  #{root_dev_path}/tty2 c 4 2"
						command.push "mknod -m 666  #{root_dev_path}/tty3 c 4 3"
						command.push "mknod -m 666  #{root_dev_path}/tty4 c 4 4"
						command.push "mknod -m 600  #{root_dev_path}/console c 5 1"
						command.push "mknod -m 666  #{root_dev_path}/full c 1 7"
						command.push "mknod -m 600  #{root_dev_path}/initctl p"
						command.push "mknod -m 666  #{root_dev_path}/ptmx c 5 2"
						command.each{ |c|
							ret = s.run c
							if s.exit_status != 0
								raise "Failed: #{c}"
							end
						}

						command_mknod_loop = String.new
						command_mknod_loop += "for i in $(seq 0 255);"
						command_mknod_loop += "do"
						command_mknod_loop += "  if [ ! -b #{root_dev_path}/loop$i ];"
						command_mknod_loop += "  then"
						command_mknod_loop += "    /bin/mknod -m 0640 #{root_dev_path}/loop$i b 7 $i;"
						command_mknod_loop += "    /bin/chown root:disk #{root_dev_path}/loop$i;"
						command_mknod_loop += "  fi;"
						command_mknod_loop += "done"
						ret = s.run command_mknod_loop
						if s.exit_status != 0
							raise "Failed: #{command_mknod_loop}"
						end

						make_dev_files_success = true
					elsif container.storage_type == LxcManager::Container::StorageType::ISCSI
						ret = s.run "iscsiadm -m discovery --type sendtargets --portal #{inter_host_network_interface_v4_address}"
						if s.exit_status == 0
							iscsiadm_discovery_success = true
						else
							raise "Failed: iscsiadm -m discovery: #{ret}"
						end

						ret = s.run "iscsiadm -m node"
						if s.exit_status == 0
							iscsiadm_node_success = true
						else
							raise "Failed: iscsiadm -m node: #{ret}"
						end

						ret = s.run "iscsiadm -m node -T iqn.2016-11.com.example:#{container.id.to_s} -p #{inter_host_network_interface_v4_address} --login"
						if s.exit_status == 0
							iscsiadm_node_login_success = true
						else
							raise "Failed: iscsiadm -m node --login: #{ret}"
						end

						ret = s.run "iscsiadm -m session"
						if s.exit_status == 0
							iscsiadm_session_success = true
						else
							raise "Failed: iscsiadm -m session"
						end

						ret = s.run "mkdir -p #{mount_lxc_path}"
						if s.exit_status == 0
							mkdir_mount_lxc_path_success = true
						else
							raise "Failed: mkdir -p: couldn't mkdir -p #{mount_lxc_path}"
						end

						ret = s.run "mountpoint -q #{mount_lxc_path}"
						if s.exit_status != 0
							disk_by_path = "/dev/disk/by-path/ip-#{inter_host_network_interface_v4_address}:3260-iscsi-iqn.2016-11.com.example:#{container.id.to_s}-lun-0"
							ret = s.run "mount -t xfs #{disk_by_path} #{mount_lxc_path}"
							if s.exit_status == 0
								mount_success = true
							else
								raise "Failed: Mount: couldn't mount #{mount_zvol_path} to #{mount_lxc_path}"
							end
						else
							mount_success = true
						end
					end

					ret = s.run "cat /proc/mounts | grep #{mount_lxc_path}"

					ret = s.run "lxc-start -n #{container.id} -d -P #{dir_mount_lxc_path}"
					if s.exit_status == 0
						lxc_start_success = true
					else
						raise "Failed: lxc-start: couldn't start #{container.name}"
					end

					# In CentOS 6 Host, sometimes devpts become ro after lxc-start/lxc-stop
					#ret = s.run "grep -E ^devpts /proc/mounts | cut -d' ' -f4 | grep -q -E ^ro && mount -t devpts -o rw,gid=5,mode=620,remount none /dev/pts || true"

					begin
						s.jump( :exit )
					rescue
					end
				rescue
					if mount_success
						ret = s.run "umount -l #{mount_lxc_path}"
					end

					if mkdir_mount_lxc_path_success
						ret = s.run "mountpoint -q #{mount_lxc_path}"
						if s.exit_status != 0
							ret = s.run "rm -rf #{mount_lxc_path}"
						else
							raise "Failed: Mount: couldn't mount #{mount_zvol_path} to #{mount_lxc_path}"
						end
					end

					if iscsiadm_node_login_success
						ret = s.run "iscsiadm -m node -T iqn.2016-11.com.example:#{container.id.to_s} -p #{inter_host_network_interface_v4_address} --logout"
						ret = s.run "iscsiadm -m session"
					end

					if mkdir_root_dev_success
						ret = s.run "rm -rf #{root_dev_path}"
					end

					if jump_success
						s.jump( :exit )
					end

					if targetcli_create_acls_success
						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/acls delete iqn.2016-11.com.example:#{container.host.name}"
					end

					if targetcli_create_portals_success
						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/portals delete #{inter_host_network_interface_v4_address} 3260"
					end

					if targetcli_create_luns_success
						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/luns delete lun0"
					end

					if targetcli_create_iscsi_success
						ret = s.run "targetcli /iscsi delete iqn.2016-11.com.example:#{container.id.to_s}"
					end

					if targetcli_create_iblock_success
						ret = s.run "targetcli /backstores/iblock delete name=#{container.id.to_s}"
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.stop config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			zfs_pool_zvol_path    = config['zfs_pool_zvol_path']
			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_zvol_path    = File.join( "/dev/zvol", zfs_pool_zvol_path, container.id.to_s )
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			inter_host_network_interface_v4_address = "#{config['inter_host_network_interface_v4_address']}"
			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			target = Hash.new
			target[:address] = container.host.v4_address
			target[:port] = '22'
			target[:user] = 'root'
			target[:auth] = :none
			target[:prompt] = /^[\[]?.+[:@].+ .+[\]]?[\#\$] /

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				jump_success = false
				lxc_stop_success = false
				stop_complete_success = false
				remove_dev_success = false
				umount_mount_success = false
				iscsiadm_node_logout_success = false
				exit_success = false
				targetcli_delete_acls_success = false
				targetcli_delete_portals_success = false
				targetcli_delete_luns_success = false
				targetcli_delete_iscsi_success = false
				targetcli_delete_iblock_success = false
				targetcli_ls_success = false

				begin
					s.jump( :ssh, target: target )
					jump_success = true

					ret = s.run "lxc-stop -n #{container.id} -P #{dir_mount_lxc_path}"
					if s.exit_status == 0
						lxc_stop_success = true
					else
						raise "Failed: lxc-stop: couldn't stop #{container.name}"
					end

					# In CentOS 6 Host, sometimes devpts become ro after lxc-start/lxc-stop
					#ret = s.run "grep -E ^devpts /proc/mounts | cut -d' ' -f4 | grep -q -E ^ro && mount -t devpts -o rw,gid=5,mode=620,remount none /dev/pts || true"

					ret = s.run "for i in {1..120}; do if [ \"$(lxc-info -n #{container.id} -s -H -P #{dir_mount_lxc_path})\" = \"STOPPED\" ]; then break; else sleep 1; fi; false; done"
					if s.exit_status == 0
						stop_complete_success = true
					else
						raise "Failed: stop container: couldn't complete stop #{container.name} in 120 sec"
					end

					if container.storage_type == LxcManager::Container::StorageType::NFS
						ret = s.run "rm -rf #{root_dev_path}"
						if s.exit_status == 0
							remove_dev_success = true
						else
							raise "Failed: remove /dev: couldn't remove /dev directory"
						end
					end

					ret = s.run "mkdir -p #{mount_lxc_path}"
					ret = s.run "mountpoint -q #{mount_lxc_path}"
					if s.exit_status == 0
						ret = s.run "umount -l #{mount_lxc_path}"
						if s.exit_status == 0
							umount_mount_success = true
						else
							raise "Failed: Umount: couldn't umount #{mount_lxc_path}"
						end
					else
						umount_mount_success = true
					end

					if container.storage_type == LxcManager::Container::StorageType::ISCSI
						ret = s.run "iscsiadm -m session"
						if s.exit_status == 0
							iscsiadm_session_success = true
						else
							raise "Failed: iscsiadm -m session"
						end

						ret = s.run "iscsiadm -m node -T iqn.2016-11.com.example:#{container.id.to_s} -p #{inter_host_network_interface_v4_address} --logout"
						if s.exit_status == 0
							iscsiadm_discovery_success = true
						else
							raise "Failed: iscsiadm -m node --logout: #{ret}"
						end

						ret = s.run "iscsiadm -m session"
						if s.exit_status == 0
							iscsiadm_session_success = true
						else
							raise "Failed: iscsiadm -m session"
						end

						ret = s.run "iscsiadm -m node"
						if s.exit_status == 0
							iscsiadm_node_success = true
						else
							raise "Failed: iscsiadm -m node: #{ret}"
						end
					end

					s.jump( :exit )
					exit_success = true

					if container.storage_type == LxcManager::Container::StorageType::ISCSI
						ret = s.run "targetcli ls /"
						if s.exit_status == 0
							targetcli_ls_success = true
						else
							raise "Failed: targetcli ls: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/acls delete iqn.2016-11.com.example:#{container.host.name}"
						if s.exit_status == 0
							targetcli_delete_acls_success = true
						else
							raise "Failed: targetcli delete acls: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/portals delete #{inter_host_network_interface_v4_address} 3260"
						if s.exit_status == 0
							targetcli_delete_portals_success = true
						else
							raise "Failed: targetcli delete portals: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1/luns delete /backstores/iblock/#{container.id.to_s}"
						if s.exit_status == 0
							targetcli_delete_luns_success = true
						else
							raise "Failed: targetcli delete luns: #{ret}"
						end

						ret = s.run "targetcli /iscsi/iqn.2016-11.com.example:#{container.id.to_s}/tpg1 set attribute authentication=0"
						if s.exit_status == 0
							targetcli_set_attribute_success = true
						else
							raise "Failed: targetcli set attribute: #{ret}"
						end

						ret = s.run "targetcli /iscsi delete iqn.2016-11.com.example:#{container.id.to_s}"
						if s.exit_status == 0
							targetcli_delete_iscsi_success = true
						else
							raise "Failed: targetcli delete iscsi: #{ret}"
						end

						ret = s.run "targetcli /backstores/iblock delete name=#{container.id.to_s} dev=#{pool_zvol_path}"
						if s.exit_status == 0
							targetcli_delete_iblock_success = true
						else
							raise "Failed: targetcli delete iblock: #{ret}"
						end

						ret = s.run "targetcli ls /"
						if s.exit_status == 0
							targetcli_ls_success = true
						else
							raise "Failed: targetcli ls: #{ret}"
						end
					end
				rescue
					raise
				end

			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.mount_zvol config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			zfs_pool_zvol_path     = config['zfs_pool_zvol_path']
			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_zvol_path    = File.join( "/dev/zvol", zfs_pool_zvol_path, container.id.to_s )
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				mkdir_pool_lxc_success = false
				mount_success = false

				begin
					ret = s.run "mkdir -p #{pool_lxc_path}"
					if s.exit_status == 0
						mkdir_pool_lxc_success = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{pool_lxc_path}"
					end

					ret = s.run "mountpoint -q #{pool_lxc_path}"
					if s.exit_status != 0
						ret = s.run "mount -t xfs #{pool_zvol_path} #{pool_lxc_path}"
						if s.exit_status == 0
							mount_success = true
						else
							raise "Failed: Mount: couldn't mount #{pool_zvol_path} to #{pool_lxc_path}"
						end
					else
						mount_success = true
					end
				rescue => e
					if mount_success
						ret = s.run "umount -l #{pool_lxc_path}"
					end

					if mkdir_pool_lxc_success
						ret = s.run "rm -rf #{pool_lxc_path}"
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.umount_zvol config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			zfs_pool_zvol_path     = config['zfs_pool_zvol_path']
			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_zvol_path    = File.join( "/dev/zvol", zfs_pool_zvol_path, container.id.to_s )
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				mkdir_pool_lxc_success = false
				umount_success = false
				rmdir_pool_lxc_success = false

				begin
					ret = s.run "mkdir -p #{pool_lxc_path}"
					if s.exit_status == 0
						mkdir_pool_lxc_success = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{pool_lxc_path}"
					end

					ret = s.run "mountpoint -q #{pool_lxc_path}"
					if s.exit_status == 0
						ret = s.run "umount -l #{pool_lxc_path}"
						if s.exit_status == 0
							umount_success = true
						else
							raise "Failed: Umount: couldn't umount #{pool_lxc_path}"
						end
					else
						umount_success = true
					end

					ret = s.run "rm -rf #{pool_lxc_path}"
					if s.exit_status == 0
						rmdir_pool_lxc_success = true
					else
						raise "Failed: rmdir: couldn't rm -rf #{pool_lxc_path}"
					end
				rescue => e
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.exportfs config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				mkdir_export_lxc_success = false
				mount_success = false
				export_success = false
				mkdir_export_share_success = false
				mount_share_success = false
				export_share_success = false

				begin
					ret = s.run "mkdir -p #{export_lxc_path}"
					if s.exit_status == 0
						mkdir_export_lxc_success = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{export_lxc_path}"
					end

					ret = s.run "mountpoint -q #{export_lxc_path}"
					if s.exit_status != 0
						ret = s.run "mount --bind #{pool_lxc_path} #{export_lxc_path}"
						if s.exit_status == 0
							mount_success = true
						else
							raise "Failed: Mount: couldn't mount #{pool_lxc_path} to #{export_lxc_path}"
						end
					else
						mount_success = true
					end

					ret = s.run "exportfs -o rw,no_root_squash,no_subtree_check,nohide #{allowed_clients}:#{export_lxc_path}"
					if s.exit_status == 0
						export_success = true
					else
						raise "Failed: export: #{allowed_clients}:#{export_lxc_path}"
					end

					ret = s.run "mkdir -p #{dir_export_share_path}"
					if s.exit_status == 0
						mkdir_export_share_success = true
					else
						raise "Failed: mkdir -p: couldn't mkdir -p #{dir_export_share_path}"
					end

					ret = s.run "mountpoint -q #{dir_export_share_path}"
					if s.exit_status != 0
						ret = s.run "mount --bind #{dir_pool_share_path} #{dir_export_share_path}"
						if s.exit_status == 0
							mount_share_success = true
						else
							raise "Failed: Mount: couldn't mount #{dir_pool_share_path} to #{dir_export_share_path}"
						end
					else
						mount_share_success = true
					end

					ret = s.run "exportfs -o rw,no_root_squash,no_subtree_check,nohide #{allowed_clients}:#{dir_export_share_path}"
					if s.exit_status == 0
						export_share_success = true
					else
						raise "Failed: export: #{allowed_clients}:#{dir_export_share_path}"
					end
				rescue => e
					if export_success
						ret = s.run "exportfs -u #{allowed_clients}:#{export_lxc_path}"
					end

					if mount_success
						ret = s.run "umount -l #{export_lxc_path}"
					end

					if mkdir_export_lxc_success
						ret = s.run "rm -rf #{export_lxc_path}"
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.unexportfs config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				uexport_success = false
				umount_export_success = false

				begin
					ret = s.run "exportfs -u #{allowed_clients}:#{export_lxc_path}"
					if s.exit_status == 0
						uexport_success = true
					else
						raise "Failed: Un-export: couldn't un-exoprt #{allowed_clients}:#{export_lxc_path}"
					end

					ret = s.run "mkdir -p #{export_lxc_path}"
					ret = s.run "mountpoint -q #{export_lxc_path}"
					if s.exit_status == 0
						ret = s.run "umount -l #{export_lxc_path}"
						if s.exit_status == 0
							umount_export_success = true
						else
							raise "Failed: Umount: couldn't umount #{export_lxc_path}"
						end
					else
						umount_export_success = true
					end

					ret = s.run "rmdir #{export_lxc_path}"
					if s.exit_status != 0
						logger.warn "#{self}##{__method__}: " + "Couldn't rmdir #{export_lxc_path}"
					end
				rescue
					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.update_parameters config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			config_file   = File.join( pool_lxc_path, 'config' )
			temporal_file = config_file + ".temp"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				copy_config_to_temporal_success = false
				update_temporal_success = false
				move_temporal_to_config_success = false

				begin
					logger.debug "#{self}##{__method__}: " + "copy #{config_file} to #{temporal_file}"
					FileUtils.copy config_file, temporal_file, preserve: true
					copy_config_to_temporal_success = true

					ret = s.run "sed -i -E 's,^lxc.rootfs = .*,lxc.rootfs = #{mount_lxc_path}/rootfs,' #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					ret = s.run "sed -i -E 's,^lxc.utsname = .*,lxc.utsname = #{container.hostname},' #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					ret = s.run "sed -i -e '/^lxc.mount.entry*/d' #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					ret = s.run "echo 'lxc.mount.entry = #{root_dev_path} dev none bind,create=dir 0 0' | tee -a #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					ret = s.run "echo 'lxc.mount.entry = #{mount_distro_path} media/cdrom none bind,create=dir 0 0' | tee -a #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					ret = s.run "echo 'lxc.mount.entry = #{dir_mount_share_path} share none bind,create=dir 0 0' | tee -a #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					update_temporal_success = true

					logger.debug "#{self}##{__method__}: " + "move #{temporal_file} to #{config_file}"
					FileUtils.move temporal_file, config_file
					move_temporal_to_config_success = true
				rescue
					if copy_config_to_temporal_success
						FileUtils.remove temporal_file, force: true
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end

		def self.update_interfaces config, container
			logger = LxcManager::Logger.instance

			logger.info "#{self}##{__method__}"

			return if LxcManager::DRY_RUN

			distro = container.distro

			template = File.join( config['template_dir'], distro.template )
			repo_url = File.join( config['repo_url'], distro.id.to_s )

			dir_pool_lxc_path     = config['dir_pool_lxc_path']
			dir_pool_share_path   = config['dir_pool_share_path']
			dir_export_lxc_path   = config['dir_export_lxc_path']
			dir_export_share_path = config['dir_export_share_path']
			dir_mount_lxc_path    = config['dir_mount_lxc_path']
			dir_mount_distro_path = config['dir_mount_distro_path']
			dir_mount_share_path  = config['dir_mount_share_path']
			dir_root_dev_path     = config['dir_root_dev_path']
			pool_lxc_path     = File.join( dir_pool_lxc_path, container.id.to_s )
			export_lxc_path   = File.join( dir_export_lxc_path, container.id.to_s )
			mount_lxc_path    = File.join( dir_mount_lxc_path, container.id.to_s )
			mount_distro_path = File.join( dir_mount_distro_path, distro.id.to_s )
			root_dev_path     = File.join( dir_root_dev_path, container.id.to_s )

			allowed_clients = "#{config['inter_host_network_v4_address']}/#{config['inter_host_network_v4_prefix']}"

			config_file   = File.join( pool_lxc_path, 'config' )
			temporal_file = config_file + ".temp"

			logger.debug "#{self}##{__method__}: " + "cli-agent start"
			CliAgent.open( config['local_shell'] ){ |s|
				copy_config_to_temporal_success = false
				update_temporal_success = false
				move_temporal_to_config_success = false

				begin
					logger.debug "#{self}##{__method__}: " + "copy #{config_file} to #{temporal_file}"
					FileUtils.copy config_file, temporal_file, preserve: true
					copy_config_to_temporal_success = true

					ret = s.run "sed -i -e '/^lxc.network*/d' #{temporal_file}"
					if s.exit_status != 0
						raise "Failed: Edit config: couldn't edit #{temporal_file}"
					end

					container.interfaces.each{ |interface|
						nw_id = interface.network.id
						bridge_if = "br#{nw_id}"

						config_lxc_network = Array.new
						config_lxc_network.push "cat <<'__EOB__' | tee -a #{temporal_file}"
						config_lxc_network.push ""
						config_lxc_network.push "lxc.network.type   = veth"
						config_lxc_network.push "lxc.network.flags  = up"
						config_lxc_network.push "lxc.network.link   = #{bridge_if}"
						config_lxc_network.push "lxc.network.name   = #{interface.name}"
						config_lxc_network.push "lxc.network.hwaddr = 00:16:3e:xx:xx:xx"
						config_lxc_network.push "lxc.network.ipv4   = #{interface.v4_address}/#{interface.network.v4_prefix} #{interface.bcast}"
						if interface.has_gw?
							config_lxc_network.push "lxc.network.ipv4.gateway = #{interface.v4_gateway}"
						end
						config_lxc_network.push ""
						config_lxc_network.push "__EOB__"
						ret = s.run config_lxc_network.join("\n")
						if s.exit_status != 0
							raise "Failed: Edit config: couldn't edit #{temporal_file}"
						end
					}

					update_temporal_success = true

					logger.debug "#{self}##{__method__}: " + "move #{temporal_file} to #{config_file}"
					FileUtils.move temporal_file, config_file
					move_temporal_to_config_success = true
				rescue
					if copy_config_to_temporal_success
						FileUtils.remove temporal_file, force: true
					end

					raise
				end
			}
			logger.debug "#{self}##{__method__}: " + "cli-agent end"
		end
	end
end
