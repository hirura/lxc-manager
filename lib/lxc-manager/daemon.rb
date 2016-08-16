# coding: utf-8

require 'thread'

require 'bundler/setup'

require_relative '../lxc-manager'
require_relative 'repo-server'
require_relative 'webui'


logger = LxcManager::Logger.instance

begin
	lxc_manager = LxcManager.new

	lxc_manager.preconfigure

	ts = Array.new

	ts.push Thread.new{
		repo_server = LxcManager::RepoServer.new
		repo_server.start
	}

	ts.push Thread.new{
		LxcManager::WebUI.run!
	}

	ts.each do |t|
		t.join
	end
rescue => e
	logger.error (["#{e.backtrace.first}: #{e.message} (#{e.class})"] + e.backtrace.drop(1)).join("\n\t")
end
require_relative '../lib/lxc-manager'

lxc_manager = LxcManager.new
config = lxc_manager.config

unless lxc_manager.users.find_by_name( 'Administrator' )
	lxc_manager.create_user( 'Administrator', 'Admin123' )
end

unless lxc_manager.networks.find_by_name( 'management' )
	lxc_manager.create_network( 'management', config['management_network_v4_address'], config['management_network_v4_prefix'], vlan_id: config['management_network_vlan_id'], host_v4_address: config['management_network_bridge_v4_address'] )
end

unless lxc_manager.distros.find_by_name( 'CentOS-6.7' )
	lxc_manager.create_distro 'CentOS-6.7', 'CentOS-6.7-x86_64-bin-DVD1.iso', 'lxc-centos67'
end

unless lxc_manager.hosts.find_by_name( 'localhost' )
	lxc_manager.create_host 'localhost', '172.16.8.51'
end
