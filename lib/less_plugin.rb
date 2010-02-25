require 'less'

module Less
	module Plugin
		extend self

		attr_reader :options

		# Set default options
		@options = {
		  :search_recursively => :true,
			:css_location => "#{RAILS_ROOT}/public/stylesheets",
			:template_location => "#{RAILS_ROOT}/app/stylesheets",
			:update => :when_changed, # Available are: :never, :when_changed and :always
			:compress => false # Removes newlines from generated CSS
		}

		# Accessor for setting options from e.g. an initializer
		def options=(opts)
			@options.merge!(opts)
		end
		
		# Determine how we're searching the file system 
    def set_recursion
      options[:search_recursively] = (options[:search_recursively] == :true) ? "**" : "/"
    end

		# Updates all stylesheets in the template_location and
		# create corresponding files in the css_location.
		def update_stylesheets
			return if options[:update] == :never

      set_recursion
      
			# Recursively loop through the directory specified in template_location.
			Dir.glob(File.join(options[:template_location], options[:search_recursively], '*.less')).each do |stylesheet|
				# Update the current stylesheet if update is not :when_changed OR when the
				# less-file is newer than the css-file.
				update_stylesheet(stylesheet) if options[:update] != :when_changed || stylesheet_needs_update?(stylesheet)
			end
		end

		private

		# Update a single stylesheet.
		def update_stylesheet(stylesheet)
			relative_path = relative_path(stylesheet)

			# Remove the old generated stylesheet
			File.unlink(File.join(options[:css_location], relative_path + ".css")) if File.exist?(File.join(options[:css_location], relative_path + ".css"))

			# Generate the new stylesheet
			Less::Command.new({:source => stylesheet, :destination => File.join(options[:css_location], relative_path + ".css"), :compress => options[:compress]}).run!
		end

		# Check if the specified stylesheet is in need of an update.
		def stylesheet_needs_update?(stylesheet)
			relative_path = relative_path(stylesheet)

			return true unless File.exist?(File.join(options[:css_location], relative_path + ".css"))
			return File.ctime(stylesheet) > File.ctime(File.join(options[:css_location], relative_path + ".css"))
		end

		# Returns the relative path for the given stylesheet
		def relative_path(stylesheet)
			stylesheet.sub(options[:template_location] + '/', '').sub('.less', '')
		end
	end
end

# Add a before_filter that triggers the update_stylesheets method
# before every call to a controller.
ActionController::Base.before_filter { Less::Plugin.update_stylesheets }