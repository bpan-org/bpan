# Set the working application directory
# working_directory "/path/to/your/app"
working_directory "/var/www/bpan-org"

# Unicorn PID file location
# pid "/path/to/pids/unicorn.pid"
pid "/var/www/bpan-org/pid/unicorn.pid"

# Path to logs
# stderr_path "/path/to/log/unicorn.log"
# stdout_path "/path/to/log/unicorn.log"
stderr_path "/var/www/bpan-org/log/unicorn.log"
stdout_path "/var/www/bpan-org/log/unicorn.log"

# Unicorn socket
# listen "/tmp/unicorn.[app name].sock"
listen "/tmp/unicorn.bpan-org.sock"

# Number of processes
# worker_processes 4
worker_processes 4

# Time-out
timeout 90
