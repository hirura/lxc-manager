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

	config = lxc_manager.config

	unless lxc_manager.users.find_by_name( 'Administrator' )
		lxc_manager.create_user( 'Administrator', 'Admin123' )
	end

	unless lxc_manager.networks.find_by_name( 'management' )
		lxc_manager.create_network( 'management', config['management_network_v4_address'], config['management_network_v4_prefix'], vlan_id: config['management_network_vlan_id'], host_v4_address: config['management_network_bridge_v4_address'] )
	end

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
