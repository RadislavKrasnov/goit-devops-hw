# DevOps Tools Installation Script
This repository contains a Bash script for automated installation of basic DevOps tools on a Linux system.

## What the script does
The script `install_dev_tools.sh` automatically installs:

- Docker
- Docker Compose (as a Docker CLI plugin)
- Python 3 (version 3.9 or newer)
- Django (installed via `pip` inside a Python virtual environment)

The script is intended to work on **Ubuntu / Debian** systems.

## How to run the script

1. Clone the repository and go to its directory:
```bash
   git clone <your-repository-url>
   cd <repository-name>
````

2. Make the script executable:

 ```bash
   chmod u+x install_dev_tools.sh
 ```

3. Run the script:

```bash
./install_dev_tools.sh
```

## How to verify installation

After the script finishes, you can check installed tools:

### Docker

```bash
docker --version
```

### Docker Compose

```bash
docker compose version
```

### Python

```bash
python3 --version
```

### Django

Django is installed inside a virtual environment located at:

```
~/django_venv
```

To verify Django:

```bash
source ~/django_venv/bin/activate
django-admin --version
deactivate
```

## Notes

* Django is installed in a virtual environment to avoid conflicts with system-managed Python packages.
* After running verification commands you should see the results similar to showed on the screenshot.

![Alt text](./img/verification-results.png)

