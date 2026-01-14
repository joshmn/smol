# Smol

A dependency-free CLI and REPL framework for Ruby. Define commands, run health checks, manage configuration from environment variables.

## Installation

```bash
gem install smol
```

Or in your Gemfile:

```ruby
gem "smol"
```

Or inline for single-file scripts:

```ruby
require "bundler/inline"

gemfile do
  gem "smol"
end
```

## Quick start

```ruby
#!/usr/bin/env ruby
require "bundler/inline"

gemfile do
  gem "smol"
end

module MyCLI
  class App < Smol::App
    banner "mycli v1.0"

    config.setting :database, default: "production", desc: "database to use"
    config.setting :verbose, default: false, type: :boolean
  end

  module Commands
    class Greet < Smol::Command
      desc "say hello"
      args :name
      aliases :g, :hello

      def call(name)
        info "hello, #{name}!"
      end
    end

    class Status < Smol::Command
      desc "run health checks"

      def call
        all_passed = run_checks(Checks::Database)
        checks_passed?(all_passed)
      end
    end
  end

  module Checks
    class Database < Smol::Check
      def call
        pass "connected to #{config[:database]}"
      end
    end
  end
end

Smol::CLI.new(MyCLI::App, prompt: "mycli").run(ARGV)
```

```bash
./mycli.rb              # starts REPL
./mycli.rb greet world  # runs single command
./mycli.rb help         # shows available commands
```

## App

The root of your CLI. Holds configuration and registered commands.

```ruby
module MyCLI
  class App < Smol::App
    banner "mycli v1.0"

    config.setting :host, default: "localhost"
    config.setting :port, default: 3000, type: :integer
    config.setting :debug, default: false, type: :boolean, desc: "enable debug"
  end
end
```

### Auto-registration

Commands and checks defined under your app's namespace register automatically:

```ruby
module MyCLI
  class App < Smol::App
    banner "mycli"
  end

  module Commands
    class Deploy < Smol::Command  # auto-registers to MyCLI::App
      desc "deploy the app"
      def call
        info "deploying..."
      end
    end
  end
end
```

The framework walks up the namespace hierarchy looking for an `App` class. Works with any nesting depth.

### Explicit registration

For control over command order in help output, register commands explicitly:

```ruby
module MyCLI
  class App < Smol::App
    banner "mycli"

    register Commands::Status   # appears first in help
    register Commands::Deploy   # appears second
    register Commands::Logs     # appears third
  end
end
```

Once you call `register`, auto-registration is disabled for that app. Commands appear in help in the order you register them.

Use explicit registration when:

- Help output order matters,
- you want to control which commands are exposed,
- or you're building a larger app where implicit behavior feels too magical.

### Mode control

Enable or disable CLI and REPL modes:

```ruby
class App < Smol::App
  cli false   # disable CLI mode (commands via arguments)
  repl false  # disable REPL mode (interactive shell)
end
```

Both default to `true`. Disabling CLI means users must run interactively. Disabling REPL means users must pass commands as arguments.

### Boot display

Control what REPL shows on startup:

```ruby
class App < Smol::App
  boot :help     # show full command list (default)
  boot :minimal  # show banner and hint only
  boot :none     # show nothing, just the prompt
end
```

### History file

Command history saves to `~/.smol_{prompt}_history` by default. Override it:

```ruby
class App < Smol::App
  history_file "~/.myapp_history"
end
```

### App methods

| Method | Purpose |
|--------|---------|
| `banner` | text shown at top of help |
| `cli` | enable/disable CLI mode |
| `repl` | enable/disable REPL mode |
| `boot` | REPL startup display (:help, :minimal, :none) |
| `history_file` | path to command history file |
| `config` | access the Config object |
| `commands` | array of registered command classes |
| `checks` | array of registered check classes |
| `mount` | mount a sub-app at a prefix |
| `find_command(name)` | look up command by name or alias |
| `register` | explicitly register a command class |

## Commands

Commands define the actions users run. Subclass `Smol::Command` and implement `call`.

```ruby
class Deploy < Smol::Command
  title "deploy to production"
  explain "pushes code, runs migrations, restarts servers"
  desc "deploy the app"
  args :environment
  aliases :d, :push

  def call(environment)
    info "deploying to #{environment}..."
    done
  end
end
```

### Class-level DSL

| Method | Purpose |
|--------|---------|
| `title` | heading shown when command runs |
| `explain` | longer description shown below title |
| `desc` | one-line description for help listing |
| `args` | positional arguments (required) |
| `option` | named arguments with flags |
| `aliases` | alternative names for the command |
| `command_name` | override the derived command name |
| `group` | group related commands in help |
| `before_action` | method to run before `call` |
| `after_action` | method to run after `call` |
| `rescue_from` | handle specific exception types |

### Instance methods

Commands include `Smol::Output` and `Smol::Input`. Additional helpers:

| Method | Purpose |
|--------|---------|
| `config` | access app configuration |
| `app` | the app class |
| `run_checks(*classes, args: [])` | run health checks |
| `checks_passed?(result, pass_hint:, fail_hint:)` | report check results |
| `checking(name)` | announce you're checking something |
| `dropping(target)` | announce you're removing something |
| `done(hint = nil)` | announce completion |

### Positional arguments

Define required arguments with `args`:

```ruby
class Greet < Smol::Command
  args :name, :greeting

  def call(name, greeting)
    info "#{greeting}, #{name}!"
  end
end
```

```bash
./mycli.rb greet alice hello  # "hello, alice!"
```

### Named options

Define optional flags with `option`:

```ruby
class Deploy < Smol::Command
  args :target
  option :env, short: :e, default: "staging", desc: "target environment"
  option :force, short: :f, type: :boolean, default: false
  option :timeout, type: :integer, default: 30

  def call(target, env:, force:, timeout:)
    info "deploying #{target} to #{env}"
  end
end
```

```bash
./mycli.rb deploy app --env=production
./mycli.rb deploy app -e production --force
./mycli.rb deploy app --timeout=60
```

Supported types: `:string` (default), `:integer`, `:boolean`.

### Command groups

Organize commands in help output:

```ruby
class Users::List < Smol::Command
  group "users"
  desc "list all users"
end

class Users::Create < Smol::Command
  group "users"
  desc "create a user"
end
```

Help displays grouped commands under their group heading.

### Callbacks

Run methods before or after `call`:

```ruby
class Deploy < Smol::Command
  before_action :check_auth
  before_action :validate_env
  after_action :notify_team

  def call(env)
    info "deploying to #{env}"
    true
  end

  private

  def check_auth
    return false unless authenticated?  # halts if false
  end

  def validate_env(env)
    failure "invalid env" unless %w[staging production].include?(env)
  end

  def notify_team(env, result:)
    info "deploy #{result ? 'succeeded' : 'failed'}"
  end
end
```

- Before actions receive the same arguments as `call`
- Return `false` to halt execution
- After actions receive arguments plus `result:` with the return value

### Error handling

Handle exceptions without crashing:

```ruby
class Deploy < Smol::Command
  rescue_from ConnectionError do |e|
    failure "connection failed: #{e.message}"
  end

  rescue_from ValidationError, with: :handle_validation

  def call
    # might raise
  end

  private

  def handle_validation(error)
    warning "invalid: #{error.message}"
  end
end
```

Unhandled exceptions propagate normally.

### Calling other commands

Commands are just Ruby classes. Call them directly:

```ruby
class Deploy < Smol::Command
  def call(env)
    Commands::Preflight.new.call
    info "deploying to #{env}..."
  end
end
```

## Checks

Health checks that return pass or fail. Subclass `Smol::Check` and implement `call`.

```ruby
class DiskSpace < Smol::Check
  def call
    available = check_disk_space_gb
    if available > 10
      pass "#{available}GB free"
    else
      fail "only #{available}GB free"
    end
  end
end
```

### Running checks

From a command:

```ruby
def call
  all_passed = run_checks(DiskSpace, DatabaseConnection, RedisConnection)
  checks_passed?(all_passed,
    pass_hint: "ready to deploy",
    fail_hint: "fix issues first"
  )
end
```

### Checks with arguments

```ruby
class IndexExists < Smol::Check
  def initialize(index_name)
    @index_name = index_name
  end

  def call
    # check @index_name exists
  end
end

# in a command:
run_checks(IndexExists, args: ["users_email_idx"])
```

### Check methods

| Method | Purpose |
|--------|---------|
| `pass(message)` | return a passing result |
| `fail(message)` | return a failing result |
| `config` | access app configuration |

## Configuration

Define settings on your app:

```ruby
config.setting :database, default: "production"
config.setting :port, default: 3000, type: :integer
config.setting :verbose, default: false, type: :boolean
config.setting :timeout, default: 30, type: :integer, desc: "request timeout"
```

### Reading values

Settings read from environment variables first (uppercased key), then fall back to defaults:

```bash
PORT=8080 ./mycli.rb  # config[:port] => 8080
```

```ruby
def call
  db = config[:database]
  port = config[:port]
end
```

### Setting values at runtime

```ruby
config.set(:database, "staging")
```

Or via CLI:

```bash
./mycli.rb config:set database staging
```

### Viewing configuration

```bash
./mycli.rb config
```

Or in REPL:

```
mycli> config
```

## Output

All output goes through `Smol::Output`. Available in commands:

| Method | Purpose |
|--------|---------|
| `info(text)` | plain text |
| `success(text)` | green, bold |
| `failure(text)` | red, bold |
| `warning(text)` | yellow |
| `hint(text)` | dim |
| `header(text)` | bold |
| `desc(text)` | dim |
| `banner(text)` | red |
| `label(text)` | yellow |
| `nl` | blank line |
| `verbose(text)` | only when `VERBOSE=1` |
| `debug(text)` | only when `DEBUG=1` |
| `check_result(name, result)` | formatted pass/fail |
| `table(rows, headers:, indent:)` | formatted table |

### Tables

```ruby
def call
  rows = [
    ["alice", "admin", "active"],
    ["bob", "user", "pending"]
  ]
  table(rows, headers: %w[name role status])
end
```

```
name   role   status
--------------------
alice  admin  active
bob    user   pending
```

### Verbose and debug modes

```ruby
def call
  verbose "extra detail"  # only with VERBOSE=1
  debug "internal state"  # only with DEBUG=1
end
```

```bash
VERBOSE=1 ./mycli.rb command
DEBUG=1 ./mycli.rb command
```

Or programmatically:

```ruby
Smol.verbose = true
Smol.debug = true
```

### Redirecting output

For testing:

```ruby
Smol.output = StringIO.new
Smol.input = StringIO.new("y\n")
```

### Logger

Standard Ruby logger for internal debugging:

```ruby
Smol.logger.level = Logger::DEBUG
Smol.logger.debug "something"
```

## Input

Interactive prompts. Available in commands via `Smol::Input`:

```ruby
def call
  name = ask("project name?")
  port = ask("port?", default: "3000")

  if confirm("create database?", default: true)
    # do it
  end

  env = choose("environment:", %w[dev staging prod], default: 1)
end
```

| Method | Purpose |
|--------|---------|
| `ask(question, default:)` | text input |
| `confirm(question, default:)` | yes/no |
| `choose(question, choices, default:)` | select from list |

## Colors

Colors use a refinement. Used internally by output methods. For custom use:

```ruby
using Smol::Colors

puts "success".green
puts "error".red
puts "warning".yellow
puts "heading".bold
puts "muted".dim
```

## Running

### CLI mode

```bash
./mycli.rb command arg1 arg2
```

Exit codes:

- `0` if command returns truthy
- `1` if command returns `false` or raises

### REPL mode

```bash
./mycli.rb  # no arguments
```

Built-in commands:

- `help` / `h` / `?` — list commands
- `config` / `c` — show configuration
- `config:set <key> <value>` — update config
- `exit` / `quit` / `q` — exit

Includes readline with history and tab completion. History saves to `~/.smol_{prompt}_history` by default. Configure via `history_file` in your App class.

## Sub-apps

Mount other apps under a prefix:

```ruby
module Admin
  class App < Smol::App
    banner "admin tools"
  end

  module Commands
    class Users < Smol::Command
      desc "manage users"
      def call
        info "listing users..."
      end
    end
  end
end

module MyCLI
  class App < Smol::App
    banner "mycli"
    mount Admin::App, as: "admin"
  end
end
```

CLI access with colon syntax:

```bash
./mycli.rb admin:users
```

REPL access by entering the sub-app:

```
mycli> admin
mycli:admin> users
mycli:admin> back
mycli>
```

## Project structure

For larger apps:

```
my_cli/
  lib/
    my_cli/
      app.rb              # MyCLI::App
      commands/
        deploy.rb         # MyCLI::Commands::Deploy
        status.rb         # MyCLI::Commands::Status
      checks/
        database.rb       # MyCLI::Checks::Database
  bin/
    mycli                 # CLI entrypoint
```

Commands and checks auto-register based on namespace. No manual wiring needed unless you want explicit control over ordering.

## License

MIT
