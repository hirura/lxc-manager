# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Host < ActiveRecord::Base
		acts_as_paranoid

		has_many :containers, dependent: :restrict_with_error

		validates :name,       presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :v4_address, presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/ }

		validate :v4_address_must_be_within_the_network_subnet

		def v4_address_must_be_within_the_network_subnet
			config  = YAML.load_file( LxcManager::CONFIG_FILE_PATH )
			network_v4_address = config['inter_host_network_v4_address']
			network_v4_prefix  = config['inter_host_network_v4_prefix']
			unless IPAddr.new("#{network_v4_address}/#{network_v4_prefix}").include? IPAddr.new("#{v4_address}/#{network_v4_prefix}")
				errors.add( :v4_address, "must be within the network subnet" )
			end
		end
	end
end

