# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class ReverseProxySubstitute < ActiveRecord::Base
		acts_as_paranoid

		belongs_to :reverse_proxy

		validates :reverse_proxy_id, presence: true
		validates :name,             presence: true, uniqueness: { scope: [:container_id], conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :pattern,          presence: true, format: { with: /\A(?:\\\\|\\'|[^'])*\z/ }
		validates :replacement,      presence: true, format: { with: /\A(?:\\\\|\\'|[^'])*\z/ }
	end
end

