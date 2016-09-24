class CreateTableReverseProxySubstitutes < ActiveRecord::Migration
	def change
		create_table :reverse_proxy_substitutes do |t|
			t.string :reverse_proxy_id, null: false
			t.string :name, null: false
			t.string :pattern, null: false
			t.string :replacement, null: false
			t.timestamps null: false
			t.time   :deleted_at
		end
	end
end
