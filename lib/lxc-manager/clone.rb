# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Clone < ActiveRecord::Base
		acts_as_paranoid

		belongs_to :snapshot

		has_one :container
	end
end

