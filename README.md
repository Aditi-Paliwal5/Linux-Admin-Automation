# Linux Admin Automation

A Linux System Administration project built using Bash scripting and CSV-based automation.

## Task 1: User and Group Management
- Create users and groups using CSV files.
- Delete users and groups.
- List existing users and groups.
- Maintain operation logs.

## Task 2: Directory Management
- Create directories using CSV input.
- Apply specified directory permissions.
- Maintain operation logs.
- Monitor disk usage.

## Task 3: System Monitoring
- Monitor CPU usage.
- Monitor memory usage.
- Monitor disk usage.
- Generate timestamped reports.
- Schedule reports using cron.

## Technologies Used
- Linux
- Bash Scripting
- CSV
- Git
- GitHub
- Cron

## Project Files
- user-group-admin.sh
- add-user-db.csv
- delete-user-db.csv
- delete-group-db.csv
- directory-manager.sh
- directories.csv
- system-monitor.sh

## How to Run

Make scripts executable:

    chmod +x user-group-admin.sh directory-manager.sh system-monitor.sh

Run Task 1:

    sudo ./user-group-admin.sh add-users
    sudo ./user-group-admin.sh delete-users
    sudo ./user-group-admin.sh delete-groups
    sudo ./user-group-admin.sh list

Run Task 2:

    sudo ./directory-manager.sh

Run Task 3:

    sudo ./system-monitor.sh

Note: Run administrative scripts with appropriate privileges. Review CSV input files before execution.
