class ChangeOptionHrefPathOfReverseProxies < ActiveRecord::Migration
	def change
		change_column :reverse_proxies, :href_path, :string, null: false
	end
end
