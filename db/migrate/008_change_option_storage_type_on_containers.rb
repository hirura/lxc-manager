class ChangeOptionStorageTypeOnContainers < ActiveRecord::Migration
	def change
		change_column :containers, :storage_type, :string, null: false
	end
end
