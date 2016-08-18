# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Snapshot < ActiveRecord::Base
		acts_as_paranoid

		belongs_to :container

		has_many :clones, dependent: :restrict_with_error

		has_many :containers, through: :clones

		validates :name,        presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :description, presence: true, format: { with: /\A.*\z/ }
	end
end

