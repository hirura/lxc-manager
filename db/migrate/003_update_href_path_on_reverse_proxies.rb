class UpdateHrefPathOnReverseProxies < ActiveRecord::Migration
	def change
		ReverseProxy.each{ |reverse_proxy|
			reverse_proxy.href_path = reverse_proxy.location
			reverse_proxy.save!
		}
	end
end
