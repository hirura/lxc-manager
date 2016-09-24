class UpdateHrefPathOnReverseProxies < ActiveRecord::Migration
	def change
		reverse_proxies = select_all( 'SELECT * FROM reverse_proxies' )
		reverse_proxies.each{ |reverse_proxy|
			id       = reverse_proxy['id']
			location = reverse_proxy['location']
			update( "UPDATE reverse_proxies SET href_path=#{location} WHERE id=#{id}" )
		}
	end
end
