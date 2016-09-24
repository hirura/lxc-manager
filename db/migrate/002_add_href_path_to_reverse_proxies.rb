class AddHrefPathToReverseProxies < ActiveRecord::Migration
	def change
		add_column :reverse_proxies, :href_path, :string, null: true
	end
end
