# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class ReverseProxy < ActiveRecord::Base
		acts_as_paranoid

		belongs_to :container

		has_many :reverse_proxy_substitutes, dependent: :destroy

		validates :container_id, presence: true
		validates :name,         presence: true, uniqueness: { scope: [:container_id], conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :listen_port,  presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }
		validates :location,     presence: true, format: { with: /\A\/.*\z/ }
		validates :proxy_port,   presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }
		validates :proxy_pass,   presence: true, format: { with: /\A\/.*\z/ }

		def assign_listen_port config
			listen_port_range = config['reverse_proxy_listen_port_range_start']..config['reverse_proxy_listen_port_range_end']
			assigned_listen_port = self.class.all.to_a.map{ |reverse_proxy| reverse_proxy.listen_port.to_i }
			listen_port_range.to_a.find{ |listen_port| ! assigned_listen_port.include? listen_port }.to_s
		end
	end
end

