# coding: utf-8

require 'bundler/setup'

require_relative '../lxc-manager'

require 'optparse'

class LxcManager
	class Cli
	end
end

if __FILE__ == $0
	params = ARGV.getopts(
		'',
		'create-container:',
		'destroy-container:',
		'create-network:',
		'destroy-network:',
		'take-snapshot:',
		'destroy-snapshot:',
		'restore-snapshot:',
		'container:',
	)
	p params
end
