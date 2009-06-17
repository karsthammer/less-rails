module ActionController
	class Base
		alias_method :less_old_process, :process

		def process(*args)
			Less::Plugin.update_stylesheets
			less_old_process(*args)
		end
	end
end
