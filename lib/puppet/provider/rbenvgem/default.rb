Puppet::Type.type(:rbenvgem).provide :default do
  desc "Maintains gems inside an RBenv setup"

  commands :su => 'su'
  commands :sudo => "sudo"

  def install
    args = ['install', '--no-rdoc', '--no-ri']
    args << "-v#{resource[:ensure]}" if !resource[:ensure].kind_of?(Symbol)
    args << [ '--source', "'#{resource[:source]}'" ] if resource[:source] != ''
    args << gem_name
    output = gem(*args)
    fail "Could not install: #{output.chomp}" if output.include?('ERROR')
  end

  def uninstall
    gem 'uninstall', '-aIx', gem_name
  end

  def latest
    @latest ||= list(:remote)
  end

  def current
    list
  end

  private
    def gem_name
      resource[:gemname]
    end

    def gem(*args)
      env = "RBENV_VERSION=#{resource[:ruby]}"
      exe = resource[:rbenv]+'/bin/gem'
      cmd = "-u#{resource[:user]}"

      sudo(cmd, env, exe, *args)
    end

    def list(where = :local)
      args = ['list', where == :remote ? '--remote' : '--local', "#{gem_name}$"]

      gem(*args).lines.map do |line|
        line =~ /^(?:\S+)\s+\((.+)\)/

        return nil unless $1

        # Fetch the version number
        ver = $1.split(/,\s*/)
        ver.empty? ? nil : ver
      end.first
    end
end
