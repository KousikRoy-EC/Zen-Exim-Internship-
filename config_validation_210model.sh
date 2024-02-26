#!/bin/bash

get_uci_value() {
    local config="$1"
    local option="$2"
    uci get "$config.$option"
}

get_config_value() {
    local interface="$1"
    local operation="$2"
    local wlan_name="$3"
    local radio="$4"

    case "$operation" in
    downloadRate)
        tc filter show dev "$interface" | grep -i "rate" | awk '{print tolower($4)}'
        ;;
    force_dhcp)
        ebtables -L | grep -q "$interface" && echo "1" || echo "0"
        ;;
    vlan)
        cat /var/run/hostapd-"$radio".conf | grep "bridge" | cut -d"=" -f2- | cut -d"-" -f2-
        ;;
    isolate)
        ebtables -t broute -L | grep "$interface" | grep -q "$wlan_name"_ISOLATE && echo "1" || echo "0"
        ;;
    epdgVoip)
        iptables -t mangle -nvL | grep -q "DSCP set 0x2e" && echo "1" || echo "0"
        ;;
    diffserv)
        tc filter show dev $interface | grep -q "filter" && echo "1" || echo "0"
        ;;
    Vlan)
        cat /var/run/hostapd-"$radio".conf | grep -w "bridge" | cut -d"=" -f2 | cut -d"-" -f2
        ;;
    qos_map_set | max_num_sta | ieee80211w | ssid | disassoc_low_ack | rsn_preauth | ft_over_ds | r1_key_holder | ft_psk_generate_local | mobility_domain | pmk_r1_push | reassociation_deadline | wnm_sleep_mode | bss_transition)
        cat /var/run/hostapd-"$radio".conf | grep -w "$operation" | cut -d"=" -f2-
        ;;
    hide_ssid)
        iw dev | grep -w -q "$interface" && echo "0" || echo "1"
        ;;
    dtim_period)
        cat /var/run/hostapd-"$radio".conf | awk '/dtim/ {last=$0} END {print last}' | cut -d"=" -f2-
        ;;
    *)
        cat /var/run/hostapd-"$radio".conf | grep -w "$operation" | cut -d"=" -f2-
        ;;
    esac
}

print_changes() {
    local wlan_name="$1"
    local intf="$2"
    local operation="$3"
    local ssid="$4"
    local val1="$5"
    local val2="$6"
    echo "changes not applied : $ssid $wlan_name $intf $operation $val1 $val2"
}

check_and_print_changes() {
    local val1="$1"
    local val2="$2"
    local wlan_name="$3"
    local intf="$4"
    local operation="$5"
    local ssid="$6"

    if [ "$operation" = "qos_map_set" ] && [ "$val1" != "$val2" ] || [ "$operation" = "downloadRate" ] && [ "$val1" != "$val2" ] || [ "$operation" = "bridge" ] && [ "$val1" != "$val2" ] || [ "$operation" = "ssid" ] && [ "$val1" != "$val2" ] || [ "$operation" = "r1_key_holder" ] && [ "$val1" != "$val2" ] || [ "$operation" = "mobility_domain" ] && [ "$val1" != "$val2" ]; then
        print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
    elif [ "$operation" != "maxsta" ] && [ "$val1" -ne "$val2" ]; then
        print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
    elif [ "$operation" = "maxsta" ] && [ "$val1" -lt 128 ] && [ "$val1" -ne "$val2" ]; then
        print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
    fi
}

process_config_option() {
    local line="$1"
    local wlan_name="$2"
    local val1
    local val2
    local operation
    local tem

    val1=$(echo "$line" | cut -d" " -f2- | tr -d "'")
    tem=$(echo "$line" | cut -d" " -f1)
    intf_cond=$(echo "$tem" | cut -d"_" -f2-)

    if [[ "$intf_cond" == "0" ]]; then
        local res=$(uci show wireless | grep "$wlan_name" | head -n1 | cut -d '.' -f1-2)
    else
        local res=$(uci show wireless | grep "$wlan_name" | tail -n1 | cut -d '.' -f1-2)
    fi

    local intf=$(get_uci_value "$res" "ifname")
    local ssid=$(get_uci_value "$res" "ssid")

    if [ "$intf" == "wlan1" ]; then
        local radio="phy1"
    else
        local radio="phy0"
    fi

    case "$tem" in
    SSID_0 | SSID_1)
        operation="ssid"
        ;;
    maxassoc_0 | maxassoc_1)
        operation="max_num_sta"
        ;;
    vlan_0 | vlan_1)
        operation="Vlan"
        ;;
    ieee80211w_0 | ieee80211w_1)
        operation="ieee80211w"
        ;;
    qosmapset_0 | qosmapset_1)
        operation="qos_map_set"
        ;;
    broadcast_0 | broadcast_1)
        operation="hide_ssid"
        ;;
    dtimPeriod_0 | dtimPeriod_1)
        operation="dtim_period"
        ;;
    ftoverds_0 | ftoverds_1)
        operation="ft_over_ds"
        ;;
    r1keyholder_0 | r1keyholder_1)
        operation="r1_key_holder"
        ;;
    ftpskgeneratelocal_0 | ftpskgeneratelocal_1)
        operation="ft_psk_generate_local"
        ;;
    mobilitydomain_0 | mobilitydomain_1)
        operation="mobility_domain"
        ;;
    pmkr1push_0 | pmkr1push_1)
        operation="pmk_r1_push"
        ;;
    reassociationdeadline_0 | reassociationdeadline_1)
        operation="reassociation_deadline"
        ;;
    wnmsleepmode_0 | wnmsleepmode_1)
        operation="wnm_sleep_mode"
        ;;
    bsstransition_0 | bsstransition_1)
        operation="bss_transition"
        ;;
    forceDhcp_0 | forceDhcp_1)
        operation="force_dhcp"
        ;;
    isolate_0 | isolate_1)
        operation="isolate"
        ;;
    rsnpreauth_0 | rsnpreauth_1)
        operation="rsn_preauth"
        ;;
    disassoclowack_0 | disassoclowack_1)
        operation="disassoc_low_ack"
        ;;
    downloadRate_0 | downloadRate_1)
        operation="downloadRate"
        ;;
    epdgVoip_0 | epdgVoip_1)
        operation="epdgVoip"
        ;;
    diffserv_0 | diffserv_1)
        operation="diffserv"
        ;;
    MSL_0 | MSL_1)
        operation="MSL"
        tempMslVal=$(iptables -t raw -nvL MAX_SESSION_LIMIT | grep -w -q "$intf" && echo "1" || echo "0")
        if [ $tempMslVal -ne $val1 ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$tempMslVal"
        fi
        return
        ;;
    encryption_0 | encryption_1)
        operation="encryption"
        if [ "$val1" == "psk-mixed+aes" ] || [ "$val1" == "psk-mixed+tkip+aes" ]; then
            local key1=$(get_uci_value "$res" "key")
            local key2=$(cat /var/run/hostapd-$radio.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 3 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "psk2+aes" ] || [ "$val1" == "psk2+tkip+aes" ]; then
            local key1=$(get_uci_value "$res" "key")
            local key2=$(cat /var/run/hostapd-$radio.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "wep" ]; then
            local key1=$(get_uci_value "$res" "key")
            local key2=$(cat /var/run/hostapd-"$radio".conf | grep "wep_key0" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 0 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "none" ]; then
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$val2" -ne 0 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "sae" ]; then
            local key1=$(get_uci_value "$res" "sae_password")
            local key2=$(cat /var/run/hostapd-$radio.conf | grep -w "sae_password" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "owe" ]; then
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "psk" ] || [ "$val1" == "psk-sae" ]; then
            local key1=$(get_uci_value "$res" "key")
            local key2=$(cat /var/run/hostapd-$radio.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$radio.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 1 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        fi
        return
        ;;
    urlfilter_0 | urlfilter_1)
        operation="url_filter"
        [ "$val1" != "0" ] && val1="1"
        val2=$(iptables -t raw -nvL | grep "URL_FILTER" | grep -v "APP_URL_FILTER" | grep -q "$intf" && echo "1" || echo "0")
        if [ "$val1" -ne "$val2" ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
        fi
        return
        ;;
    macfilter_0 | macfilter_1)
        operation="macaddr_acl"
        local tempVal2=$(cat /var/run/hostapd-"$radio".conf | grep -w "$operation" | cut -d"=" -f2-)
        if [ "$val1" == "allow" ] && [ "$tempVal2" -ne 1 ] || [ "$val1" == "" ] && [ "$tempVal2" -eq 1 ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$tempVal2"
        fi
        return
        ;;
    rts_0 | rts_1)
        operation="rts"
        rts_val=$(iwconfig $intf | grep "RTS thr" | awk '{print $2}' | cut -d'=' -f2 | cut -d":" -f2)
        if [ $val1 = "off" ] && [ $rts_val != "off" ] || [ $rts_val != $val1 ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$rts_val"
        fi
        return
        ;;
    disabled_0 | disabled_1)
        operation="disabled"
        disable=$(iw dev | grep -w -q "$ssid" && echo "0" || echo "1")
        if [ $disable -ne $val1 ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$disable"
        fi
        return
        ;;
    *)
        operation=$(echo "$tem" | cut -d"_" -f1)
        ;;
    esac
    val2=$(get_config_value "$intf" "$operation" "$wlan_name" "$radio")
    check_and_print_changes "$val1" "$val2" "$wlan_name" "$intf" "$operation" "$ssid"
}

compare_wireless_configs() {
    local wlan_name="$1"
    local res_0=$(uci show wireless | grep "$wlan_name" | head -n1 | cut -d '.' -f1-2)
    local res_1=$(uci show wireless | grep "$wlan_name" | tail -n1 | cut -d '.' -f1-2)

    local SSID_0=$(get_uci_value "$res_0" "ssid")
    local encryption_0=$(get_uci_value "$res_0" "encryption")
    local disabled_0=$(get_uci_value "$res_0" "disabled")
    local broadcast_0=$(get_uci_value "$res_0" "hidden")
    local maxassoc_0=$(get_uci_value "$res_0" "maxassoc")
    local dtimPeriod_0=$(get_uci_value "$res_0" "dtim_period")
    local ftoverds_0=$(get_uci_value "$res_0" "ft_over_ds")
    local r1keyholder_0=$(get_uci_value "$res_0" "r1_key_holder")
    local ftpskgeneratelocal_0=$(get_uci_value "$res_0" "ft_psk_generate_local")
    local mobilitydomain_0=$(get_uci_value "$res_0" "mobility_domain")
    local pmkr1push_0=$(get_uci_value "$res_0" "pmk_r1_push")
    local reassociationdeadline_0=$(get_uci_value "$res_0" "reassociation_deadline")
    local wnmsleepmode_0=$(get_uci_value "$res_0" "wnm_sleep_mode")
    local bsstransition_0=$(get_uci_value "$res_0" "bss_transition")
    local forceDhcp_0=$(get_uci_value "$res_0" "force_dhcp")
    local isolate_0=$(get_uci_value "$res_0" "isolate")
    local rts_0=$(get_uci_value "$res_0" "rts_threshold")
    local rsnpreauth_0=$(get_uci_value "$res_0" "rsn_preauth")
    local disassoclowack_0=$(get_uci_value "$res_0" "disassoc_low_ack")
    local vlan_0=$(get_uci_value "$res_0" "network")
    local ieee80211w_0=$(get_uci_value "$res_0" "ieee80211w")
    local qosmapset_0=$(get_uci_value "$res_0" "iw_qos_map_set")
    local urlfilter_0=$(get_uci_value "$res_0" "url_filter")
    local macfilter_0=$(get_uci_value "$res_0" "macfilter")
    local downloadRate_0=$(get_uci_value "$res_0" "download_rate")
    local MSL_0=$(get_uci_value "$res_0" "MSL")

    echo -e "appFilter_0 '$appFilter_0'\ndiffserv_0 '$diffserv_0'\nepdgVoip_0 '$epdgVoip_0'\nMSL_0 '$MSL_0'\ndownloadRate_0 '$downloadRate_0'\nmacfilter_0 '$macfilter_0'\nurlfilter_0 '$urlfilter_0'\nqosmapset_0 '$qosmapset_0'\nieee80211w_0 '$ieee80211w_0'\nvlan_0 '$vlan_0'\nencryption_0 '$encryption_0'\nSSID_0 '$SSID_0'\ndisassoclowack_0 '$disassoclowack_0'\nrsnpreauth_0 '$rsnpreauth_0'\nrts_0 '$rts_0'\nisolate_0 '$isolate_0'\nforceDhcp_0 '$forceDhcp_0'\nftoverds_0 '$ftoverds_0'\nr1keyholder_0 '$r1keyholder_0'\nftpskgeneratelocal_0 '$ftpskgeneratelocal_0'\nmobilitydomain_0 '$mobilitydomain_0'\npmkr1push_0 '$pmkr1push_0'\nreassociationdeadline_0 '$reassociationdeadline_0'\nwnmsleepmode_0 '$wnmsleepmode_0'\nbsstransition_0 '$bsstransition_0'\ndtimPeriod_0 '$dtimPeriod_0'\nbroadcast_0 '$broadcast_0'\ndisabled_0 '$disabled_0'\nmaxassoc_0 '$maxassoc_0'" >"$file"

    if [ "$res_0" != "$res_1" ]; then
        local SSID_1=$(get_uci_value "$res_1" "ssid")
        local encryption_1=$(get_uci_value "$res_1" "encryption")
        local disabled_1=$(get_uci_value "$res_1" "disabled")
        local broadcast_1=$(get_uci_value "$res_1" "hidden")
        local maxassoc_1=$(get_uci_value "$res_1" "maxassoc")
        local dtimPeriod_1=$(get_uci_value "$res_1" "dtim_period")
        local ftoverds_1=$(get_uci_value "$res_1" "ft_over_ds")
        local r1keyholder_1=$(get_uci_value "$res_1" "r1_key_holder")
        local ftpskgeneratelocal_1=$(get_uci_value "$res_1" "ft_psk_generate_local")
        local mobilitydomain_1=$(get_uci_value "$res_1" "mobility_domain")
        local pmkr1push_1=$(get_uci_value "$res_1" "pmk_r1_push")
        local reassociationdeadline_1=$(get_uci_value "$res_1" "reassociation_deadline")
        local wnmsleepmode_1=$(get_uci_value "$res_1" "wnm_sleep_mode")
        local bsstransition_1=$(get_uci_value "$res_1" "bss_transition")
        local forceDhcp_1=$(get_uci_value "$res_1" "force_dhcp")
        local isolate_1=$(get_uci_value "$res_1" "isolate")
        local rts_1=$(get_uci_value "$res_1" "rts_threshold")
        local rsnpreauth_1=$(get_uci_value "$res_1" "rsn_preauth")
        local disassoclowack_1=$(get_uci_value "$res_1" "disassoc_low_ack")
        local vlan_1=$(get_uci_value "$res_1" "network")
        local ieee80211w_1=$(get_uci_value "$res_1" "ieee80211w")
        local qosmapset_1=$(get_uci_value "$res_1" "iw_qos_map_set")
        local urlfilter_1=$(get_uci_value "$res_1" "url_filter")
        local macfilter_1=$(get_uci_value "$res_1" "macfilter")
        local downloadRate_1=$(get_uci_value "$res_1" "download_rate")
        local MSL_1=$(get_uci_value "$res_1" "MSL")

        echo -e "appFilter_1 '$appFilter_1'\ndiffserv_1 '$diffserv_1'\nepdgVoip_1 '$epdgVoip_1'\nMSL_1 '$MSL_1'\ndownloadRate_1 '$downloadRate_1'\nmacfilter_1 '$macfilter_1'\nurlfilter_1 '$urlfilter_1'\nqosmapset_1 '$qosmapset_1'\nieee80211w_1 '$ieee80211w_1'\nvlan_1 '$vlan_1'\nencryption_1 '$encryption_1'\nSSID_1 '$SSID_1'\ndisassoclowack_1 '$disassoclowack_1'\nrsnpreauth_1 '$rsnpreauth_1'\nrts_1 '$rts_1'\nisolate_1 '$isolate_1'\nforceDhcp_1 '$forceDhcp_1'\nftoverds_1 '$ftoverds_1'\nr1keyholder_1 '$r1keyholder_1'\nftpskgeneratelocal_1 '$ftpskgeneratelocal_1'\nmobilitydomain_1 '$mobilitydomain_1'\npmkr1push_1 '$pmkr1push_1'\nreassociationdeadline_1 '$reassociationdeadline_1'\nwnmsleepmode_1 '$wnmsleepmode_1'\nbsstransition_1 '$bsstransition_1'\ndtimPeriod_1 '$dtimPeriod_1'\nbroadcast_1 '$broadcast_1'\ndisabled_1 '$disabled_1'\nmaxassoc_1 '$maxassoc_1'" >>"$file"
    fi
    while IFS= read -r line1; do
        process_config_option "$line1" "$wlan_name"
    done <"$file" >>"result"
    rm -f "$file"
}

fetchAllSSID() {
    local file="data"
    rm -f result
    SSID_list=$(uci show wireless | grep -w "name" | cut -d"=" -f2 | cut -d"_" -f1 | cut -d"'" -f2- | uniq)
    for wlan_name in $SSID_list; do
        sleep 1s && compare_wireless_configs "$wlan_name"
    done
}

fetchAllSSID
