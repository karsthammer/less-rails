require 'less'

module Less
	module Plugin
		extend self

		attr_reader :options

		@options = {
			:css_location => "#{RAILS_ROOT}/public/stylesheets",
			:template_location => "#{RAILS_ROOT}/app/stylesheets",
			:update => :when_changed
		}

		def options=(opts)
			@options.merge!(opts)
		end

		def update_stylesheets
			return if @options[:update] == :never

			Dir.glob(File.join(options[:template_location], '**', '*.less')).each do |less_file|
				relative_path = less_file.sub(options[:template_location] + '/', '')

				# Remove the old generated stylesheet
				File.unlink(File.join(options[:css_location], relative_path.sub('.less', '.css'))) if File.exist?(File.join(options[:css_location], relative_path.sub('.less', '.css')))

				# Generate the new stylesheet
				Less::Command.new({:source => less_file, :destination => File.join(options[:css_location], relative_path.sub('.less', '.css'))}).compile
			end
		end
	end
end

ActionController::Base.before_filter { Less::Plugin.update_stylesheets }
