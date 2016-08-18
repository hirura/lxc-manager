# coding: utf-8

require 'ipaddr'

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Interface < ActiveRecord::Base
		acts_as_paranoid

		belongs_to :network
		belongs_to :container

		validates :network_id,   presence: true
		validates :container_id, presence: true
		validates :name,         presence: true, uniqueness: { scope: [:container_id], conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-z][a-z0-9]{,9}\z/ }
		validates :v4_address,   presence: true, format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/ }

		validate :v4_address_must_be_within_the_network_subnet

		def v4_address_must_be_within_the_network_subnet
			network_v4_address = self.network.v4_address
			network_v4_prefix  = self.network.v4_prefix
			unless IPAddr.new("#{network_v4_address}/#{network_v4_prefix}").include? IPAddr.new("#{v4_address}/#{network_v4_prefix}")
				errors.add( :v4_address, "must be within the network subnet" )
			end
		end

		def assign_v4_address
			network_v4_address = self.network.v4_address
			network_v4_prefix  = self.network.v4_prefix
			v4_addresses = IPAddr.new("#{network_v4_address}/#{network_v4_prefix}").to_range.to_a[1..-2]
			assigned_v4_addresses = self.class.all.to_a.map{ |i| i.v4_address }
			v4_addresses.map{ |addr| addr.to_s }.find{ |addr| ! assigned_v4_addresses.include? addr.to_s }.to_s
		end

		def bcast
			network_v4_address = self.network.v4_address
			network_v4_prefix  = self.network.v4_prefix
			IPAddr.new("#{network_v4_address}/#{network_v4_prefix}").to_range.to_a.last
		end

		def has_gw?
			if self.v4_gateway
				true
			else
				false
			end
		end

		def unique_name_in_container?
			self.container.interfaces.select{ |interface|
				! interface.deleted_at
			}.any?{ |interface| interface.name == name }
		end
	end
end

