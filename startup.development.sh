#!/usr/bin/env bash
# ##############################################################################
# Starting script for PPP-Table project folder.
# Creates configs directory and related environmental variables for accessing
# local database and running python virtualenv.
#
# Dependencies: mysql-client, mysql login-path
#
# Other env vars (optional):
#   - DB_HOST: ip address to use in configs/ files (default is 192.168.2.12)
#   - DB_PORT: port to use in configs/ files (default is 3306)
#
# ##############################################################################
cd "$(dirname "$0")" || exit 1

# [Project names and paths]
# Update these values where applicable

project="$(pwd)"
cnf_filename="my.cnf"
login_path="andre"
mysqlhost=${DB_HOST:-"192.168.2.12"}
mysqlport=${DB_PORT:-"3306"}
pippath="${project}/requirements.txt"

if [ "$(uname -s)" == "Linux" ]; then
    macos=false
fi
# FIXME: check output from WSL and update if needed.
macos=${macos:=true}

# [Environment setup]

# if configs/ exists, prompt to rebuild or pass.
# Else if configs/ D.N.E. then ask for MySQL user credentials and
# build environmental vars.
if [ -d "${project}/configs" ];
then
    echo -e "Rebuild local project directory and update sql configurations? \n"
    echo -n "[y/n] "
    read -r response
    first=${response:0:1}
    first=$(echo "$first" | tr '[:upper:]' '[:lower:]')
    if [ "${first}" == "n" ]; then
        rebuild=false
    fi
fi
rebuild=${rebuild:=true}
mkdir -p "${project}"/configs
(
    cd "${project}"/configs || exit 1
    if ! wget --no-clobber https://storage.googleapis.com/mdg-servers-pcs/andre/mysql-ca/andre-ca-cert.pem; then
        echo "[warning] Failed to download SSL cert file."
        echo "You will need to do this manually. Use the URL below and to download:"
        echo "  https://storage.googleapis.com/mdg-servers-pcs/andre/mysql-ca/andre-ca-cert.pem"
        echo
        echo "Continuing install..."
    fi
)

# Build python virtualenv environment using pip and requirements file.
if [ ! -d "${project}/venv" ]; then
	if ! python3 -m virtualenv -p python3 "${project}"/venv; then
    	echo "[error] could not install python dependencies."
        echo "Please check that virtualenv is installed and on your PATH."
        exit 1
    fi
    # FIXME: update for WSL path seperators
    echo -e "\nsource ${project}/configs/.env" >> "${project}"/venv/bin/activate
fi

assert_command_exists() {
    if ! command -v "$1" &> /dev/null
    then
        echo "$0: error: $1 could not be found"
        echo "Check that it's installed and in your \$PATH"
        exit
    fi
}

# if mac then install mysqlclient via homebrew (before attempting requirements.txt)
if $macos; then
    echo "Checking for installation of mysql via homebrew..."
    brew list mysql-client
    if [ $? -eq  1 ]; then
        echo "MacOS installing mysql via homebrew..."
        brew install mysql-client
    else
        echo "mysql-client already installed, continuing."
    fi
    assert_command_exists mysql
    assert_command_exists mysql_config
    #FIXME: does this need to be pip from virtualenv?
    pip install mysqlclient

else
    # Check if mysqlclient is installed on the system
    if [ -z "$(command -v mysql)" ]; then
        echo "[error] mysql-client package not found"
        echo
        echo "You need mysql-client to continue with the install."
        echo "To install from command line, run:"
        echo "      apt-get install mysql-client python3-dev default-libmysqlclient-dev"
        echo
        echo "Please install mysql and rerun this setup script."
        exit 1
    fi
fi


echo "Installing python dependencies..."
if ! "${project}"/venv/bin/pip install -r "${pippath}"; then
    echo "[warning] Unable to locate requirements file at ${pippath}"
    echo "Continuing with install ..."
    "${project}"/venv/bin/pip install git+ssh://git@github.com/mountaindatagroup/mdg-connection@master
fi
echo

if $rebuild;
then
# Rebuilding configs dir. Remove existing, clone mdg repo "configs", ask
# user for MySQL credentials.  Write paths, credentials and other project
# vars to: ".env" and "env.py".
echo "Rebuilding configuration files..."

# Use MDGConnection to write cnf file from login-path. Use default login-path=Andre.
# If this fails, then promp the user for credentials.
if ! "${project}"/venv/bin/python -c \
"from mdgconnection import MDGConnection; con = MDGConnection(loginpath='$login_path'); con.to_mycnf('${project}/configs/${cnf_filename}')" 2&> /dev/null;
then
echo
echo "[warning] No mysql login path for '$login_path' found."
echo
echo -e "Enter credentials for Andre mysql: \n"
echo -n "MySQL Username: "
read -r user
echo -n "MySQL Password: "
read -r -s pw
echo

cat >"${project}"/configs/"${cnf_filename}" <<EOF
[client]
user=${user}
password=${pw}
host=$mysqlhost
port=$mysqlport
EOF

else
user="$(grep user "${project}"/configs/"${cnf_filename}" | sed 's/user=//')"
pw="$(grep password "${project}"/configs/"${cnf_filename}" | sed 's/password=//')"
fi

# For R
cat >"${project}"/configs/.Renviron<<EOF
DB_USER="$user"
DB_PW="$pw"
DB_HOST="$mysqlhost"
DB_PORT=$mysqlport
SSL_PATH="${project}/configs/andre-ca-cert.pem"
EOF

cat >"${project}"/configs/.env<<EOF
# development environmental vars
export DB_USER="${user}"
export DB_PW="${pw}"
export DB_HOST="$mysqlhost"
export DB_PORT="$mysqlport"
export PROJECT_DIR="${project}"
export SSL_PATH="${project}/configs/andre-ca-cert.pem"
EOF

fi
echo

echo "Installing R packages..."
(
    cd "${project}" || exit 1
    R -e "source('renv/activate.R'); source('setup.R')"
)
echo
echo "Install complete!"
