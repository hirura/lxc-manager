class CreateInitialTables < ActiveRecord::Migration
	def change
		create_table :users do |t|
			t.string :name, null: false
			t.string :password_salt, null: false
			t.string :password_hash, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :hosts do |t|
			t.string :name, null: false
			t.string :v4_address, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :distros do |t|
			t.string :name, null: false
			t.string :iso, null: false
			t.string :template, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :networks do |t|
			t.string :name, null: false
			t.string :vlan_id, null: false
			t.string :v4_address, null: false
			t.string :v4_prefix, null: false
			t.string :host_v4_address
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :containers do |t|
			t.string :clone_id
			t.string :host_id
			t.string :distro_id, null: false
			t.string :name, null: false
			t.string :hostname, null: false
			t.string :description, null: false
			t.string :state, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :interfaces do |t|
			t.string :network_id, null: false
			t.string :container_id, null: false
			t.string :name, null: false
			t.string :v4_address, null: false
			t.string :v4_gateway
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :napts do |t|
			t.string :container_id, null: false
			t.string :name, null: false
			t.string :sport, null: false
			t.string :dport, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :reverse_proxies do |t|
			t.string :container_id, null: false
			t.string :name, null: false
			t.string :listen_port, null: false
			t.string :location, null: false
			t.string :proxy_port, null: false
			t.string :proxy_pass, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :snapshots do |t|
			t.string :container_id, null: false
			t.string :name, null: false
			t.string :description, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :clones do |t|
			t.string :snapshot_id, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end

		create_table :storage_histories do |t|
			t.timestamps null: false
			t.time   :deleted_at
		end
	end
end
