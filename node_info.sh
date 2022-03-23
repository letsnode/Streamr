#!/bin/bash
# Default variables
language="EN"
raw_output="false"

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo $1 | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script shows information about a Streamr node"
		echo
		echo -e "Usage: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h,  --help               show help page"
		echo -e "  -l,  --language LANGUAGE  use the LANGUAGE for texts"
		echo -e "                            LANGUAGE is '${C_LGn}EN${RES}' (default), '${C_LGn}RU${RES}'"
		echo -e "  -ro, --raw-output         the raw JSON output"
		echo
		echo -e "You can use either \"=\" or \" \" as an option and value ${C_LGn}delimiter${RES}"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Streamr/blob/main/node_info.sh - script URL"
		echo -e "         (you can send Pull request with new texts to add a language)"
		echo -e "https://teletype.in/@letskynode/Streamr_staking_EN — English-language guide"
		echo -e "https://teletype.in/@letskynode/Streamr_staking_RU — Russian-language guide"
		echo -e "https://t.me/letskynode — node Community"
		echo -e "https://teletype.in/@letskynode — guides and articles"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-l*|--language*)
		if ! grep -q "=" <<< $1; then shift; fi
		language=`option_value $1`
		shift
		;;
	-ro|--raw-output)
		raw_output="true"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
main() {
	# Texts
	if [ "$language" = "RU" ]; then
		local t_niw1="Нода работает:      ${C_LGn}да${RES}"
		local t_niw2="Нода работает:      ${C_LR}нет${RES}"
		local t_ewa_err="${C_LR}Не удалось получить адрес кошелька!${RES}\n"
		local t_wa="Адрес кошелька:     ${C_LGn}%s${RES}\n"
		
		local t_apr="APR:                ${C_LGn}%.2f%%${RES}"
		local t_apy="APY:                ${C_LGn}%.2f%%${RES}\n"
		
		local t_bal="Баланс:             ${C_LGn}%.2f${RES} DATA / ${C_LGn}%.2f${RES}$"
		local t_nop="Количество выплат:  ${C_LGn}%d${RES}"
		local t_rr="Наград получено:    ${C_LGn}%.2f${RES} DATA / ${C_LGn}%.2f${RES}$\n"		
		
	# Send Pull request with new texts to add a language - https://github.com/SecorD0/Streamr/blob/main/node_info.sh
	#elif [ "$language" = ".." ]; then
	else
		local t_niw1="Node is working:     ${C_LGn}yes${RES}"
		local t_niw2="Node is working:     ${C_LR}no${RES}"	
		local t_ewa_err="${C_LR}Failed to get the wallet address!${RES}\n"
		local t_wa="Wallet address:      ${C_LGn}%s${RES}\n"
		
		local t_apr="APR:                 ${C_LGn}%.2f%%${RES}"
		local t_apy="APY:                 ${C_LGn}%.2f%%${RES}\n"
		
		local t_bal="Balance:             ${C_LGn}%.2f${RES} DATA / ${C_LGn}%.2f${RES}$"
		local t_nop="Number of payments:  ${C_LGn}%d${RES}"
		local t_rr="Rewards received:    ${C_LGn}%.2f${RES} DATA / ${C_LGn}%.2f${RES}$\n"
	fi
	
	# Actions
	sudo apt install jq bc -y &>/dev/null
	
	if docker ps -a | grep streamr_node | grep -q Up; then
		local n_i_w="true"
	else
		local n_i_w="false"
	fi
	local wallet_address=`docker logs streamr_node | grep -oPm1 "(?<=Network node )([^%]+)(?=\#)"`
	
	local wallet_info=`wget -qO- "https://brubeck1.streamr.network:3013/stats/$wallet_address"`
	local rewards_info=`wget -qO- https://brubeck1.streamr.network:3013/apy`
	
	local apr=`jq -r .\"24h-APR\" <<< "$rewards_info"`
	local apy=`jq -r .\"24h-APY\" <<< "$rewards_info"`
	
	local DATA_price=`. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/parsers/token_price.sh) -ts streamr`
	
	local balance_DATA=`wget -qO- 'https://polygon-rpc.com/' --header "Content-Type: application/json" --post-data '{"jsonrpc":"2.0","id":2,"method":"eth_call","params":[{"from":"0x0000000000000000000000000000000000000000","data":"0x70a08231000000000000000000000000'$(sed 's%0x%%' <<< "$wallet_address")'","to":"0x3a9a81d576d83ff21f26f325066054540720fc34"},"latest"]}' | jq -r ".result"`
	local balance_DATA=`sed 's%0x%%' <<< "$balance_DATA"`
	local balance_DATA=`bc <<< "scale=2; $(bc <<< "ibase=16; ${balance_DATA^^}")/10^18"`
	local balance_USDT=`bc <<< "$DATA_price*$balance_DATA"`
	
	local n_o_p=`jq -r ".claimCount" <<< "$wallet_info"`
	local rewards_DATA=`wget -qO- "https://brubeck1.streamr.network:3013/datarewards/$wallet_address" | jq ".DATA"`
	if [ "$rewards_DATA" = "null" ] || [ "$rewards_DATA" -eq 0 ]; then
		local rewards_DATA="0.00"
		local rewards_USDT="0.00"
	else
		local rewards_USDT=`bc <<< "$DATA_price*$rewards_DATA"`
	fi

	# Output
	if [ "$raw_output" = "true" ]; then
		printf_n '{"node_is_working": %b, "wallet_address": "%s", "apr": %.2f, "apy": %.2f, "number_of_payments": %d, "rewards_DATA": %.2f, "rewards_USDT": %.2f}' \
"$n_i_w" \
"$wallet_address" \
"$apr" \
"$apy" \
"$n_o_p" \
"$rewards_DATA" \
"$rewards_USDT" 2>/dev/null
	else
		printf_n
		if [ "$n_i_w" = "true" ]; then
			printf_n "$t_niw1"
		else
			printf_n "$t_niw2"
		fi
		if [ -n "$wallet_address" ]; then
			printf_n "$t_wa" "$wallet_address"
			
			printf_n "$t_apr" "$apr"
			printf_n "$t_apy" "$apy"
			
			printf_n "$t_bal" "$balance_DATA" "$balance_USDT"
			printf_n "$t_nop" "$n_o_p"
			printf_n "$t_rr" "$rewards_DATA" "$rewards_USDT"
		else
			printf_n "$t_ewa_err"
			
			printf_n "$t_apr" "$apr"
			printf_n "$t_apy" "$apy"
			
			printf_n "$t_bal" "$balance_DATA" "$balance_USDT"
		fi
	fi
}

main
