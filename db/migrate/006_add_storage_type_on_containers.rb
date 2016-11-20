class AddStorageTypeOnContainers < ActiveRecord::Migration
	def change
		add_column :containers, :storage_type, :string, null: true
		add_column :containers, :size_gb, :integer, null: true
	end
end
