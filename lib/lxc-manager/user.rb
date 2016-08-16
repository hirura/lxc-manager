# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'
require 'bcrypt'

class LxcManager
	class User < ActiveRecord::Base
		acts_as_paranoid

		validates :name,          presence: true, uniqueness: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9@._-]{,99}\z/ }
		validates :password_salt, presence: true
		validates :password_hash, presence: true

		def self.generate_salt
			BCrypt::Engine.generate_salt
		end

		def self.generate_hash password, password_salt
			BCrypt::Engine.hash_secret( password, password_salt )
		end

		def self.authenticate_by_id id, password
			user = self.find( id )
			if user && user.password_hash == self.generate_hash( password, user.password_salt )
				user
			else
				raise "Authentication failed."
			end
		end

		def self.authenticate_by_name name, password
			user = self.find_by_name( name )
			if user && user.password_hash == self.generate_hash( password, user.password_salt )
				user
			else
				raise "Authentication failed."
			end
		end
	end
end

