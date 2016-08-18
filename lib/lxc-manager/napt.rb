# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Napt < ActiveRecord::Base
		acts_as_paranoid

		belongs_to :container

		validates :container_id, presence: true
		validates :name,         presence: true, uniqueness: { scope: [:container_id], conditions: -> { where( deleted_at: nil ) } }, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :sport,        presence: true, uniqueness: { conditions: -> { where( deleted_at: nil ) } }, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }
		validates :dport,        presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 65535 }

		def assign_sport config
			sport_range = config['napt_sport_range_start']..config['napt_sport_range_end']
			assigned_sport = self.class.all.to_a.map{ |napt| napt.sport.to_i }
			sport_range.to_a.find{ |sport| ! assigned_sport.include? sport }.to_s
		end
	end
end

