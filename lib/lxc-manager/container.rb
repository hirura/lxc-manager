# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Container < ActiveRecord::Base
		module StorageType
			NFS   ||= 'NFS'
			ISCSI ||= 'iSCSI'
		end

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

		validates :name,         presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :hostname,     presence: true, format: { with: /\A[a-z][a-z0-9-]{,61}[a-z0-9]\z/ }
		validates :description,  presence: true, format: { with: /\A.*\z/ }
		validates :state,        presence: true, inclusion: { in: [RUNNING, STOPPED, UNKNOWN] }
		validates :storage_type, presence: true, inclusion: { in: [StorageType::NFS, StorageType::ISCSI] }
		validates :size_gb,      numericality: { only_integer: true, allow_nil: true }

		validate :state_cannot_be_running_because_same_address_is_already_active_in_network
		validate :size_gb_cannot_be_blank_when_storage_type_is_iscsi

		def state_cannot_be_running_because_same_address_is_already_active_in_network
			if state == RUNNING
				conflict_interfaces = interfaces.select{ |interface|
					v4_address = interface.v4_address
					network = interface.network
					same_address_interfaces = network.interfaces.select{ |interface2| interface2.v4_address == v4_address }
					other_interfaces = same_address_interfaces.select{ |interface2| interface2.id != interface.id }
					other_interfaces.any?{ |interface2| interface2.container.state == RUNNING }
				}
				if conflict_interfaces.any?
					errors.add( :state, "connot be running because address #{conflict_interfaces.map{ |i| i.v4_address }.join(', ')} is already active in network #{conflict_interfaces.map{ |i| i.network.name }.join(', ')}" )
				end
			end
		end

		def size_gb_cannot_be_blank_when_storage_type_is_iscsi
			if storage_type == StorageType::ISCSI
				if size_gb.to_s.size == 0
					errors.add( :size_gb, "connot benk when storage type is iscsi" )
				end
			end
		end
	end
end
