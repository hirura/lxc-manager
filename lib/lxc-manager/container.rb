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
		validates :state,       presence: true
	end
end

