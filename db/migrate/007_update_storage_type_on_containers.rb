class UpdateStorageTypeOnContainers < ActiveRecord::Migration
	def change
		update( "UPDATE containers SET storage_type='NFS'" )
	end
end
