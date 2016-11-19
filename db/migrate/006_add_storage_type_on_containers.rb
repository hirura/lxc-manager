class AddStorageTypeOnContainers < ActiveRecord::Migration
	def change
		add_column :containers, :storage_type, :string, null: true
	end
end
