#!/usr/bin/env bash
# shellcheck disable=SC2144

parse_spf_record() {
	declare -a dns_record
	local fqdn=${1}
	dns_record=($(dig txt "${fqdn}"|grep -oE 'v=spf[0-9] [^"]+'))
	for entry in ${dns_record[*]}; do
			case ${entry} in
				a )     dig +short "${fqdn}" ;;
				mx )    parse_mx_record "${fqdn}" ;;
				ip4:* ) echo "${entry#*:}" ;;
				ip6:* ) echo "${entry#*:}" ;;
				redirect=* ) parse_spf_record "${entry#*=}" ;;
				include:* )  parse_spf_record "${entry#*:}" ;;
			esac
	done
}

parse_mx_record() {
	declare -a mx_records
	local fqdn=${1}
	mx_records=($(dig +short mx "${fqdn}" | cut -d\  -f2))
	for entry in ${mx_records[*]}; do
		dig +short "${entry}"
	done
}

sort_results(){
	declare -a ipv4 ipv6
	while read -r line ; do
		if [[ ${line} =~ : ]] ; then
			ipv6+=("${line}")
		else
			ipv4+=("${line}")
		fi
	done
	[[ -v ipv4[@] ]] && printf '%s\n' "${ipv4[@]}" | sort -g -t. -k1,1 -k 2,2 -k 3,3 -k 4,4 | uniq
	[[ -v ipv6[@] ]] && printf '%s\n' "${ipv6[@]}" | sort -g -t: -k1,1 -k 2,2 -k 3,3 -k 4,4 -k 5,5 -k 6,6 -k 7,7 -k 8,8 | uniq
}

#===============================================================================
# Main
#===============================================================================
set -o nounset

parse_spf_record "${1}" | sort_results
