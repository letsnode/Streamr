#!/bin/bash
# Default variables
function="install"
completely="false"

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script performs many actions related to a Streamr node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help        show the help page"
		echo -e "  -up, --update      update the node"
		echo -e "  -un, --uninstall   uninstall the node"
		echo -e "  -c,  --completely  uninstall the node completely (${C_R}including $HOME/.streamr${RES})"
		echo
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Streamr/blob/main/multi_tool.sh — script URL"
		echo -e "https://teletype.in/@letskynode/Streamr_staking_EN — English-language guide"
		echo -e "https://teletype.in/@letskynode/Streamr_staking_RU — Russian-language guide"
		echo -e "https://t.me/letskynode — node Community"
		echo -e "https://teletype.in/@letskynode — guides and articles"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-up|--update)
		function="update"
		shift
		;;
	-un|--uninstall)
		function="uninstall"
		shift
		;;
	-c|--completely)
		completely="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
install() {
	printf_n "${C_LGn}Node installation...${RES}"
	local pk
	if [ ! -f $HOME/.streamr/config/default.json ]; then
		printf "\n${C_LGn}Enter Etherium wallet private key:${RES} "
		read -r pk
	else
		local pk=`jq -r ".client.auth.privateKey" $HOME/.streamr/config/default.json`
	fi
	sudo apt update
	sudo apt upgrade -y
	sudo apt install git jq expect build-essential -y
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/installers/docker.sh)
	expect <<END
	set timeout 300
	spawn docker run -it --rm -v $HOME/.streamr:/root/.streamr streamr/broker-node bin/config-wizard
	expect "Do you want to generate"
	send -- "\033\[B\n"
	expect "Please provide the private key"
	send -- "$pk\n"
	expect "Select the plugins"
	send -- "\n"
	expect "Do you want to participate"
	send -- "Y\n"
	expect "Select a path to store"
	send -- "\n"
	set timeout 10
	expect "The selected destination"
	send -- "y\n"
	expect eof
END
	docker run -dit --restart always --name streamr_node -p 7170:7170 -p 7171:7171 -p 1883:1883 -v $HOME/.streamr:/root/.streamr streamr/broker-node
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n streamr_log -v "docker logs streamr_node -fn 100" -a
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n streamr_node_info -v ". <(wget -qO- https://raw.githubusercontent.com/SecorD0/Streamr/main/node_info.sh) -l RU 2> /dev/null" -a
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
	printf_n "
The node was ${C_LGn}started${RES}.

\tv ${C_LGn}Useful commands${RES} v

To view the node log: ${C_LGn}streamr_log${RES}
To view the node info: ${C_LGn}streamr_node_info${RES}
To delete the node container: ${C_LGn}docker stop streamr_node; docker rm streamr_node${RES}
To restart the node: ${C_LGn}docker restart streamr_node${RES}
"
}
update() {
	printf_n "${C_LGn}Checking for update...${RES}"
	status=`docker pull streamr/broker-node`
	if ! grep -q "Image is up to date for" <<< "$status"; then
		printf_n "${C_LGn}Updating...${RES}"
		docker stop streamr_node
		docker rm streamr_node
		docker run -dit --restart always --name streamr_node -p 7170:7170 -p 7171:7171 -p 1883:1883 -v $HOME/.streamr:/root/.streamr streamr/broker-node
	else
		printf_n "${C_LGn}Node version is current!${RES}"
	fi
}
uninstall() {
	printf_n "${C_LGn}Node uninstalling...${RES}"
	docker stop streamr_node
	docker rm streamr_node
	docker rmi streamr/broker-node
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n streamr_log -da
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n streamr_node_info -da
	if [ "$completely" = "true" ]; then
		rm -rf $HOME/.streamr
	fi
	printf_n "${C_LGn}Done!${RES}"
}

# Actions
cd
sudo apt install wget -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
$function
