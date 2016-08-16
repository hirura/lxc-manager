# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Network < ActiveRecord::Base
		acts_as_paranoid
		validates_as_paranoid
		validates_uniqueness_of_without_deleted :name, :vlan_id

		has_many :interfaces, dependent: :restrict_with_error

		has_many :containers, through: :interfaces

		validates :name,       presence: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :vlan_id,    presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 4094 }
		validates :v4_address, presence: true, format: { with: /\A(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\z/ }
		validates :v4_prefix,  presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 12, less_than_or_equal_to: 30 }

		def self.assign_vlan_id config
			available_vlans = (config['service_network_vlan_range_start']..config['service_network_vlan_range_end']).to_a
			assigned_vlans  = all.map{ |network| network.vlan_id.to_i }
			available_vlans.find{ |vlan_id| ! assigned_vlans.include? vlan_id.to_i }
		end
	end
end
