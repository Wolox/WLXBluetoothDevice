class XCodeBuild

  ACTIONS = %w(
    clean
    build
    test
    archive
    analyze
    install
  )

  DEFAULT_ACTION_ARGUMENTS = {
    'test' => {
      'sdk' => 'iphonesimulator'
    }
  }

  class << self

    def to_action_method_name(action)
      if ACTIONS.include?(action)
        action.downcase.gsub("-", "_")
      end
    end

  end

  attr_reader :workspace, :scheme

  def initialize(workspace, scheme, opts = {})
    @workspace = workspace
    @scheme = scheme
    opts = {verbose: false, dry_run: false, pretty: true}.merge(opts)
    @pretty = opts[:pretty]
    @verbose = opts[:verbose]
    @dry_run = opts[:dry_run]
  end

  def pretty?
    @pretty
  end

  def run(action, arguments = {}, options = {})
    if valid_action?(action)
      options = default_base_options.merge(options)
      arguments = DEFAULT_ACTION_ARGUMENTS.fetch(action, {}).merge(arguments)
      command = build_command(action, arguments, options)
      execute(command)
    else
      raise "Invalid action #{action}"
    end
  end

  def dry_run?
    @dry_run
  end

  def verbose?
    @verbose
  end

  ACTIONS.each do |action|
    define_method(to_action_method_name(action)) do |*args|
      run(action, *args)
    end
  end

  private

    def build_command(action, arguments, options)
      options = to_options_string(options)
      arguments = to_options_string(arguments)
      cmd = "xcodebuild #{options} #{action} #{arguments}".strip
      cmd += " | xcpretty -c" if pretty?
      cmd
    end

    def execute(command)
      log("Executing command '#{command}'")
      system(command) unless dry_run?
    end

    def valid_action?(action)
      ACTIONS.include?(action)
    end

    def log(message)
      puts "#{self.class}: #{message}" if verbose?
    end

    def default_base_options
      @default_base_options ||= { workspace: workspace, scheme: scheme }
    end

    def to_options_string(options = {})
      options.reduce("") do |options_string, (key, value)|
        if value
          options_string + " -#{key} #{value}"
        else
          options_string + " -#{key}"
        end
      end
    end

end