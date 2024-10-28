# Abusaa Networking Script

**`abusaa-networking.sh`** is a comprehensive Bash script developed by **Eng. Mohammad Motasem Abusaa**. It streamlines the process of selecting, downloading, and installing QEMU images from `.yml` templates, providing essential features such as CPU monitoring, automatic retries, and pagination for large collections of files. This script is ideal for users managing extensive QEMU environments on EVE-NG.

## Features

- **Paginated Display**: Navigate through `.yml` files in pages, allowing quick selection even in directories with many files.
- **Automated QEMU Image Installation**: Finds and installs QEMU images based on selected `.yml` templates.
- **CPU Usage Monitoring**: Avoids CPU overload by pausing installations if usage exceeds the set threshold.
- **Retry Mechanism**: Automatically retries failed installations up to a specified number of attempts, ensuring installation reliability.
- **Dependency Management**: Checks for required dependencies (like `ishare2`) and installs them if missing.
- **User-Friendly Interface**: Enhanced colored output and prompts improve readability and guide the user step-by-step.

## Requirements

- **Linux environment** with Bash installed.
- **Dependencies**:
  - **`ishare2`**: Essential for QEMU image management, automatically installed if not present.
  - **`top` command**: Required for monitoring CPU usage.

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/mohammadabusaa66/abusaa-networking.git
cd abusaa-networking
```

### 2. Make the Script Executable

```bash
chmod +x abusaa-networking.sh
```

### 3. Run the Script

```bash
./abusaa-networking.sh
```

## Usage

### Running the Script

Upon running the script, a menu displays `.yml` files in pages. Files are located in `/opt/unetlab/html/templates/intel/`, where you can choose specific images to install.

### Filtering Descriptions

- **Enter a keyword** to filter `.yml` descriptions, displaying only files that match the keyword.
- **Press `Enter`** without typing to display all files.

### Selecting a File

- **Enter the file’s number** to select it, or type `all` to install all displayed images.
- The script will prompt for confirmation before installation.

### Installation Process

- **CPU Monitoring**: Installation pauses when CPU usage exceeds the threshold (default: `70%`), resuming once usage is reduced.
- **Retries**: Each image installation includes a retry mechanism to handle intermittent failures (e.g., network issues).

### Example Workflow

1. Start the script.
2. Filter files based on a keyword (optional).
3. Select a file to install or install all files.
4. Confirm the installation when prompted.
5. Monitor installation progress with real-time CPU usage checks.

## Configuration

Several variables within the script can be adjusted:

- **`CPU_THRESHOLD`**: Maximum CPU usage allowed before pausing installations (default: `70`).
- **`COOLDOWN_INTERVAL`**: Time in seconds to wait if CPU usage is high (default: `5`).
- **`PAUSE_BETWEEN_INSTALLS`**: Interval between each installation to avoid CPU strain (default: `10`).
- **`MAX_RETRIES`**: Number of retry attempts for failed installations (default: `3`).

## Troubleshooting

- **“Command not found” Errors**: Ensure all dependencies are installed, or rerun the script to auto-install `ishare2`.
- **High CPU Usage Pauses**: If installations are pausing frequently, consider increasing `CPU_THRESHOLD` or decreasing `COOLDOWN_INTERVAL`.
- **Permissions Issues**: Ensure you have execute permissions for `abusaa-networking.sh` (`chmod +x abusaa-networking.sh`).
- **Installation Failures**: Check network connectivity and increase `MAX_RETRIES` if needed.

## Contribution

Contributions to `abusaa-networking.sh` are welcome! To contribute:

1. **Fork the repository** on GitHub.
2. **Create a new branch** for your feature or bug fix.
3. **Submit a pull request** explaining the changes and their benefits.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Developed and maintained by **Eng. Mohammad Motasem Abusaa**. Special thanks to the open-source community for providing the tools and resources that make this project possible.
