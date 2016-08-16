# coding: utf-8

require 'bundler/setup'
require 'active_record'
require 'acts_as_paranoid'

class LxcManager
	class Distro < ActiveRecord::Base
		acts_as_paranoid
		validates_as_paranoid
		validates_uniqueness_of_without_deleted :name

		has_many :containers, dependent: :restrict_with_error

		validates :name,     presence: true, format: { with: /\A[a-zA-Z][a-zA-Z0-9 @._-]{,99}\z/ }
		validates :iso,      presence: true, format: { with: /\A[a-zA-Z0-9][a-zA-Z0-9@._-]{,95}\.iso\z/ }
		validates :template, presence: true, format: { with: /\A[a-zA-Z0-9][a-zA-Z0-9@._-]{,99}\z/ }

		validate :iso_must_be_in_the_iso_pool_dir
		validate :template_must_be_in_the_template_dir

		def iso_must_be_in_the_iso_pool_dir
			config  = YAML.load_file( LxcManager::CONFIG_FILE_PATH )
			iso_pool_dir = config['dir_pool_iso_path']
			unless File.exists? File.join( iso_pool_dir, iso )
				errors.add( :iso, "must be in #{iso_pool_dir}" )
			end
		end

		def template_must_be_in_the_template_dir
			config  = YAML.load_file( LxcManager::CONFIG_FILE_PATH )
			template_dir = config['template_dir']
			unless File.exists? File.join( template_dir, template )
				errors.add( :template, "must be in #{template_dir}" )
			end
		end
	end
end

