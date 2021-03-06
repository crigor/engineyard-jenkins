require 'thor/group'

module Engineyard
  module Jenkins
    class InstallServerGenerator < Thor::Group
      include Thor::Actions
      
      class_option :plugins, :aliases => '-p', :desc => 'additional Jenkins CI plugins (comma separated)'
      
      def self.source_root
        File.join(File.dirname(__FILE__), "install_server_generator", "templates")
      end
      
      def cookbooks
        directory "cookbooks"
      end
      
      def attributes
        @plugins = %w[git-1.1.6 github-0.4 rake-1.7.6 ruby-1.2 greenballs-1.10 envfile-1.1] + (options[:plugins] || '').strip.split(/\s*,\s*/)
        template "attributes.rb.tt", "cookbooks/jenkins_master/attributes/default.rb"
      end
      
    end
  end
end
