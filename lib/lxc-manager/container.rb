# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Container < ActiveRecord::Base
		RUNNING ||= 'running'
		STOPPED ||= 'stopped'
		UNKNOWN ||= 'unknown'

		acts_as_paranoid

		belongs_to :clone, dependent: :destroy
		belongs_to :host
		belongs_to :distro

		has_many :interfaces,      dependent: :destroy
		has_many :napts,           dependent: :destroy
		has_many :reverse_proxies, dependent: :destroy
		has_many :snapshots,       dependent: :restrict_with_error

		has_many :networks, through: :interfaces

		validates :name,        presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :hostname,    presence: true, format: { with: /\A[a-z][a-z0-9-]{,61}[a-z0-9]\z/ }
		validates :description, presence: true, format: { with: /\A.*\z/ }
		validates :state,       presence: true, inclusion: { in: [RUNNING, STOPPED, UNKNOWN] }

		validate :state_cannot_be_running_because_same_address_is_already_active

		def state_cannot_be_running_because_same_address_is_already_in_use
			conflict_interfaces = interfaces.select{ |interface|
				v4_address = interface.v4_address
				network = interface.network
				network.interfaces.find_all_by_v4_address( v4_address ).select{ |all_interface| all_interface.id != interface.id }.any?{ |other_interface| other_interface.container.state == RUNNING }
			}
			if conflict_interfaces.any?
				errors.add( :state, "connot be running because address #{conflict_interfaces.map{ |i| i.v4_address }.join(', ')} is already active in network #{conflict_interfaces.map{ |i| i.network.name }.join(', ')}" )
			end
		end
	end
end
