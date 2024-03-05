#!/bin/bash

get_uci_value() {
    local config="$1"
    local option="$2"
    uci get "$config.$option"
}

get_iwpriv_value() {
    local interface="$1"
    local operation="$2"
    local wlan_name="$3"

    case "$operation" in
    dis_legacy)
        local var=$("$command" "$interface" g_"$operation" | cut -d":" -f2- | awk '{gsub(/^ +| +$/,"")} {print $0}')
        case "$var" in
        0)
            echo "1"
            ;;
        1)
            echo "2"
            ;;
        3)
            echo "5.5"
            ;;
        7)
            echo "11"
            ;;
        31)
            echo "9"
            ;;
        63)
            echo "12"
            ;;
        127)
            echo "18"
            ;;
        255)
            echo "24"
            ;;
        *)
            echo "6"
            ;;
        esac
        ;;
    bcn_rate)
        local var=$("$command" "$interface" get_"$operation" | cut -d":" -f2- | awk '{gsub(/^ +| +$/,"")} {print $0}')
        case "$var" in
        2000)
            echo "2"
            ;;
        5500)
            echo "5.5"
            ;;
        6000)
            echo "6"
            ;;
        11000)
            echo "11"
            ;;
        12000)
            echo "12"
            ;;
        24000)
            echo "24"
            ;;
        *)
            echo "1"
            ;;
        esac
        ;;
    downloadRate)
        tc filter show dev "$interface" | grep -i "rate" | awk '{print tolower($4)}'
        ;;
    force_dhcp)
        ebtables -L | grep -q "$interface" && echo "1" || echo "0"
        ;;
    vlan)
        cat /var/run/hostapd-"$interface".conf | grep "bridge" | cut -d"=" -f2- | cut -d"-" -f2-
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
    app_filter)
        iptables -t mangle -nvL | grep "APP_FILTER" | grep -w -q "$interface" && echo "1" || echo "0"
        ;;
    qos_map_set | ieee80211w | ssid | disassoc_low_ack | rsn_preauth | ft_over_ds | r1_key_holder | ft_psk_generate_local | mobility_domain | pmk_r1_push | reassociation_deadline | wnm_sleep_mode | bss_transition)
        cat /var/run/hostapd-"$interface".conf | grep -w "$operation" | cut -d"=" -f2-
        ;;
    *)
        "$command" "$interface" get_"$operation" | awk -F':' '{print $2}'
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

    if ([ "$operation" = "users_to_router" ] || [ "$operation" = "users_to_brouter" ] || [ "$operation" = "brouter_to_users" ] || [ "$operation" = "trusted-users" ] || [ "$operation" = "trusted-users-to-router" ]) && [ "$val1" != "$val2" ]; then
        print_changes "$wlan_name" "$operation" "$ssid" "$val1" "$val2"
    elif ([ "$operation" = "qos_map_set" ] || [ "$operation" = "downloadRate" ] || [ "$operation" = "bridge" ] || [ "$operation" = "ssid" ] || [ "$operation" = "r1_key_holder" ] || [ "$operation" = "mobility_domain" ]) && [ "$val1" != "$val2" ]; then
        print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
    elif ([ "$operation" = "walledgarden_port_list" ] || [ "$operation" = "gatewayname" ] || [ "$operation" = "gatewayfqdn" ] || [ "$operation" = "preauth" ] || [ "$operation" = "binauth" ] || [ "$operation" = "authenticated_users" ] || [ "$operation" = "authserver" ] || [ "$operation" = "acctserver" ] || [ "$operation" = "qn_fqdn" ] || [ "$operation" = "qn_path" ] || [ "$operation" = "uamsecret" ] || [ "$operation" = "nasid" ] || [ "$operation" = "walledgarden_fqdn_list" ] || [ "$operation" = "gatewayinterface" ]) && [ "$val1" != "$val2" ]; then
        print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
    elif [ "$operation" != "max_num_sta" ] && [ "$val1" != "$val2" ] || [ "$operation" != "max_num_sta" ] && [ "$val1" -ne "$val2" ]; then
        print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$val2"
    elif [ "$operation" = "max_num_sta" ] && [ "$val1" -lt 128 ] && [ "$val1" -ne "$val2" ]; then
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

    case "$tem" in
    SSID_0 | SSID_1)
        operation="ssid"
        ;;
    maxassoc_0 | maxassoc_1)
        operation="maxsta"
        ;;
    mgmtRate_0 | mgmtRate_1)
        case "$val1" in
        1)
            "$command" "$intf" dis_legacy 0x0000
            ;;
        2)
            "$command" "$intf" dis_legacy 0x0001
            ;;
        5.5)
            "$command" "$intf" dis_legacy 0x0003
            ;;
        6)
            "$command" "$intf" dis_legacy 0x000f
            ;;
        9)
            "$command" "$intf" dis_legacy 0x001f
            ;;
        11)
            "$command" "$intf" dis_legacy 0x0007
            ;;
        12)
            "$command" "$intf" dis_legacy 0x003f
            ;;
        18)
            "$command" "$intf" dis_legacy 0x007f
            ;;
        24)
            "$command" "$intf" dis_legacy 0x00ff
            ;;
        *)
            "$command" "$intf" dis_legacy 0x000f
            ;;
        esac
        operation="dis_legacy"
        ;;
    bssRate_0 | bssRate_1)

        case "$val1" in
        0)
            return
            ;;
        1)
            "$command" "$intf" set_bcn_rate 1000
            ;;
        2)
            "$command" "$intf" set_bcn_rate 2000
            ;;
        5.5)
            "$command" "$intf" set_bcn_rate 5500
            ;;
        6)
            "$command" "$intf" set_bcn_rate 6000
            ;;
        11)
            "$command" "$intf" set_bcn_rate 11000
            ;;
        12)
            "$command" "$intf" set_bcn_rate 12000
            ;;
        24)
            "$command" "$intf" set_bcn_rate 24000
            ;;
        *)
            "$command" "$intf" set_bcn_rate 1000
            ;;
        esac
        operation="bcn_rate"
        ;;
    vlan_0 | vlan_1)
        operation="vlan"
        ;;
    rrm_0 | rrm_1)
        operation="rrm"
        ;;
    uapsd_0 | uapsd_1)
        operation="uapsd"
        ;;
    pureg_0 | pureg_1)
        operation="pureg"
        ;;
    ieee80211w_0 | ieee80211w_1)
        operation="ieee80211w"
        ;;
    qosmapset_0 | qosmapset_1)
        operation="qos_map_set"
        ;;
    wmm_0 | wmm_1)
        operation="wmm"
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
    proxyarp_0 | proxyarp_1)
        operation="proxyarp"
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
    appFilter_0 | appFilter_1)
        [ "$val1" != "0" ] && val1="1"
        operation="app_filter"
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
            local key2=$(cat /var/run/hostapd-$intf.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 3 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "psk2+aes" ] || [ "$val1" == "psk2+tkip+aes" ]; then
            local key1=$(get_uci_value "$res" "key")
            local key2=$(cat /var/run/hostapd-$intf.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "ccmp" ]; then
            local key1=$(get_uci_value "$res" "sae_password")
            local key2=$(cat /var/run/hostapd-$intf.conf | grep -w "sae_password" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "psk2+ccmp" ]; then
            local key1=$(get_uci_value "$res" "sae_password")
            local key2=$(cat /var/run/hostapd-$intf.conf | grep -w "sae_password" | cut -d"=" -f2-)
            local key_1=$(get_uci_value "$res" "key")
            local key_2=$(cat /var/run/hostapd-$intf.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$key_1" != "$key_2" ] || [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "wep" ]; then
            local key1=$(get_uci_value "$res" "key1")
            local key2=$(iwconfig $intf | grep -o 'Encryption key:[^ ]*' | cut -d ':' -f 2 | tr -d '-')
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key1" != "$key2" ] || [ "$val2" -ne 2 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "none" ]; then
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$val2" -ne 0 ]; then
                print_changes "$wlan_name" "$intf" "$operation" "$ssid" "" ""
            fi
        elif [ "$val1" == "psk" ]; then
            local key_1=$(get_uci_value "$res" "key")
            local key_2=$(cat /var/run/hostapd-$intf.conf | grep -w "wpa_passphrase" | cut -d"=" -f2-)
            local val2=$(cat /var/run/hostapd-$intf.conf | grep "wpa=" | cut -d"=" -f2)
            if [ "$key_1" != "$key_2" ] || [ "$val2" -ne 1 ]; then
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
        operation="maccmd"
        local tempVal2=$("$command" $intf get_$operation | awk -F':' '{print $2}')
        if [ "$val1" == "deny" ] && [ "$tempVal2" -ne 2 ] || [ "$val1" == "allow" ] && [ "$tempVal2" -eq 0 ] || [ "$val1" == "" ] && [ "$tempVal2" -eq 1 ] || [ "$tempVal2" -eq 2 ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$tempVal2"
        fi
        return
        ;;
    rts_0 | rts_1)
        operation="rts"
        rts_val=$(iwconfig $intf | grep "RTS thr" | awk '{print $2}' | cut -d'=' -f2 | cut -d":" -f2)
        if [ $val1 = "off" ] && [ $rts_val != "off" ] || [ $rts_val != $val1 ]; then #err
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$rts_val"
        fi
        return
        ;;
    disabled_0 | disabled_1)
        operation="disabled"
        disable=$(iwconfig | grep -w "$ssid" | grep -w -q "$intf" && echo "0" || echo "1") #no need to comp intf
        if [ $disable -ne $val1 ]; then
            print_changes "$wlan_name" "$intf" "$operation" "$ssid" "$val1" "$disable"
        fi
        return
        ;;
    *)
        operation=$(echo "$tem" | cut -d"_" -f1)
        ;;
    esac
    val2=$(get_iwpriv_value "$intf" "$operation" "$wlan_name")
    check_and_print_changes "$val1" "$val2" "$wlan_name" "$intf" "$operation" "$ssid"
}

check_opennds_config() {
    local line="$1"
    local wlan_name="$2"
    local res=$(uci show wireless | grep "$wlan_name" | head -n1 | cut -d '.' -f1-2)
    local opennds_config=$(cat /tmp/etc/opennds_$wlan_name.conf)
    local radius_config=$(cat /tmp/etc/opennds_radius_$wlan_name.conf)
    local ssid=$(get_uci_value "$res" "ssid")
    local param=$(echo "$line" | cut -d" " -f1)
    local val1=$(echo "$line" | cut -d" " -f2- | tr -d "'")
    local val2=""

    case "$param" in
    debuglevel | gatewayname | gatewayfqdn | maxclients | preauthidletimeout | checkinterval | ratecheckwindow | uploadquota | downloadquota | uploadrate | downloadrate | trafficcontrol | clientisolation | preauth | binauth | authidletimeout | sessiontimeout | uamsecret | walledgarden_fqdn_list | gatewayport)
        val2=$(echo "$opennds_config" | grep -w "$param" | cut -d" " -f2)
        ;;
    firewall_termination_enabled)
        val2=$(echo "$opennds_config" | grep -w "$param" | cut -d" " -f3-)
        ;;
    qn_fqdn)
        val2=$(echo "$opennds_config" | grep -w "walledgarden_fqdn_list" | cut -d" " -f2-)
        ;;
    walledgarden_port_list)
        val1=$(uci show opennds | grep "$wlan_name.walledgarden_port_list" | cut -d"=" -f2 | sed "s/'//g")
        val2=$(echo "$opennds_config" | grep -w "walledgarden_port_list" | cut -d" " -f2)
        tempval2=$(echo "$opennds_config" | grep -w "walledgarden_port_list" | cut -d" " -f3)
        check_and_print_changes "$val1" "${val2} ${tempval2}" "$wlan_name" "" "$param" "$ssid"
        return
        ;;
    gatewayinterface)
        val1=$(uci show opennds | grep "$wlan_name.gatewayinterface" | cut -d"=" -f2 | sed "s/'//g")
        val2=$(echo "$opennds_config" | grep -w "GatewayInterface" | cut -d" " -f2)
        tempval2=$(echo "$opennds_config" | grep -w "GatewayInterface" | cut -d" " -f3)
        check_and_print_changes "$val1" "${val2} ${tempval2}" "$wlan_name" "" "$param" "$ssid"
        return
        ;;
    radius_timeout | radius_retries | authserver | acctserver)
        val2=$(echo "$radius_config" | grep -w "$param" | cut -d" " -f2)
        ;;
    nasid)
        val2=$(echo "$radius_config" | grep -w "nas-identifier" | cut -d" " -f2)
        ;;
    enabled)
        val2=1
        ;;
    opennds)
        val2="$wlan_name"
        ;;
    authenticated_users)
        echo "$opennds_config" | grep -w -q "FirewallRule allow all" && val2="allow all"
        ;;
    users_to_router | users_to_brouter | brouter_to_users | trusted-users | trusted-users-to-router)
        param=$(echo "$param" | sed 's/_/-/g')
        awk "/^FirewallRuleSet $param/,/^}/" /tmp/etc/opennds_$wlan_name.conf | grep -w "$val1" >/dev/null && val2="$val1"
        ;;
    *)
        return
        ;;
    esac
    check_and_print_changes "$val1" "$val2" "$wlan_name" "-" "$param" "$ssid"
}

compare_wireless_configs() {
    local wlan_name="$1"
    local res_0=$(uci show wireless | grep "$wlan_name" | head -n1 | cut -d '.' -f1-2)
    local res_1=$(uci show wireless | grep "$wlan_name" | tail -n1 | cut -d '.' -f1-2)

    local SSID_0=$(get_uci_value "$res_0" "ssid")
    local encryption_0=$(get_uci_value "$res_0" "encryption")
    local disabled_0=$(get_uci_value "$res_0" "disabled")
    local broadcast_0=$(get_uci_value "$res_0" "hidden")
    local uapsd_0=$(get_uci_value "$res_0" "uapsd")
    local rrm_0=$(get_uci_value "$res_0" "rrm")
    local maxassoc_0=$(get_uci_value "$res_0" "maxassoc")
    local pureg_0=$(get_uci_value "$res_0" "pureg")
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
    local rts_0=$(get_uci_value "$res_0" "rts")
    local rsnpreauth_0=$(get_uci_value "$res_0" "rsn_preauth")
    local disassoclowack_0=$(get_uci_value "$res_0" "disassoc_low_ack")
    local proxyarp_0=$(get_uci_value "$res_0" "proxyarp")
    local vlan_0=$(get_uci_value "$res_0" "network")
    local bssRate_0=$(get_uci_value "$res_0" "bss_rate")
    local mgmtRate_0=$(get_uci_value "$res_0" "mgmt_rate")
    local ieee80211w_0=$(get_uci_value "$res_0" "ieee80211w")
    local qosmapset_0=$(get_uci_value "$res_0" "qos_map_set")
    local urlfilter_0=$(get_uci_value "$res_0" "url_filter")
    local macfilter_0=$(get_uci_value "$res_0" "macfilter")
    local wmm_0=$(get_uci_value "$res_0" "wmm")
    local downloadRate_0=$(get_uci_value "$res_0" "download_rate")
    local MSL_0=$(get_uci_value "$res_0" "MSL")
    local epdgVoip_0=$(get_uci_value "$res_0" "epdg_voip")
    local diffserv_0=$(get_uci_value "$res_0" "diffserv_8")
    local appFilter_0=$(get_uci_value "$res_0" "app_filter")

    echo -e "appFilter_0 '$appFilter_0'\ndiffserv_0 '$diffserv_0'\nepdgVoip_0 '$epdgVoip_0'\nMSL_0 '$MSL_0'\ndownloadRate_0 '$downloadRate_0'\nwmm_0 '$wmm_0'\nmacfilter_0 '$macfilter_0'\nurlfilter_0 '$urlfilter_0'\nqosmapset_0 '$qosmapset_0'\nieee80211w_0 '$ieee80211w_0'\nbssRate_0 '$bssRate_0'\nmgmtRate_0 '$mgmtRate_0'\nvlan_0 '$vlan_0'\nencryption_0 '$encryption_0'\nSSID_0 '$SSID_0'\nproxyarp_0 '$proxyarp_0'\ndisassoclowack_0 '$disassoclowack_0'\nrsnpreauth_0 '$rsnpreauth_0'\nrts_0 '$rts_0'\nisolate_0 '$isolate_0'\nforceDhcp_0 '$forceDhcp_0'\nftoverds_0 '$ftoverds_0'\nr1keyholder_0 '$r1keyholder_0'\nftpskgeneratelocal_0 '$ftpskgeneratelocal_0'\nmobilitydomain_0 '$mobilitydomain_0'\npmkr1push_0 '$pmkr1push_0'\nreassociationdeadline_0 '$reassociationdeadline_0'\nwnmsleepmode_0 '$wnmsleepmode_0'\nbsstransition_0 '$bsstransition_0'\npureg_0 '$pureg_0'\ndtimPeriod_0 '$dtimPeriod_0'\nbroadcast_0 '$broadcast_0'\ndisabled_0 '$disabled_0'\nuapsd_0 '$uapsd_0'\nrrm_0 '$rrm_0'\nmaxassoc_0 '$maxassoc_0'" >"$file"

    if [ "$res_0" != "$res_1" ]; then
        local SSID_1=$(get_uci_value "$res_1" "ssid")
        local encryption_1=$(get_uci_value "$res_1" "encryption")
        local disabled_1=$(get_uci_value "$res_1" "disabled")
        local broadcast_1=$(get_uci_value "$res_1" "hidden")
        local uapsd_1=$(get_uci_value "$res_1" "uapsd")
        local rrm_1=$(get_uci_value "$res_1" "rrm")
        local maxassoc_1=$(get_uci_value "$res_1" "maxassoc")
        local pureg_1=$(get_uci_value "$res_1" "pureg")
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
        local rts_1=$(get_uci_value "$res_1" "rts")
        local rsnpreauth_1=$(get_uci_value "$res_1" "rsn_preauth")
        local disassoclowack_1=$(get_uci_value "$res_1" "disassoc_low_ack")
        local proxyarp_1=$(get_uci_value "$res_1" "proxyarp")
        local vlan_1=$(get_uci_value "$res_1" "network")
        local bssRate_1=$(get_uci_value "$res_1" "bss_rate")
        local mgmtRate_1=$(get_uci_value "$res_1" "mgmt_rate")
        local ieee80211w_1=$(get_uci_value "$res_1" "ieee80211w")
        local qosmapset_1=$(get_uci_value "$res_1" "qos_map_set")
        local urlfilter_1=$(get_uci_value "$res_1" "url_filter")
        local macfilter_1=$(get_uci_value "$res_1" "macfilter")
        local wmm_1=$(get_uci_value "$res_1" "wmm")
        local downloadRate_1=$(get_uci_value "$res_1" "download_rate")
        local MSL_1=$(get_uci_value "$res_1" "MSL")
        local epdgVoip_1=$(get_uci_value "$res_1" "epdg_voip")
        local diffserv_1=$(get_uci_value "$res_1" "diffserv_8")
        local appFilter_1=$(get_uci_value "$res_1" "app_filter")

        echo -e "appFilter_1 '$appFilter_1'\ndiffserv_1 '$diffserv_1'\nepdgVoip_1 '$epdgVoip_1'\nMSL_1 '$MSL_1'\ndownloadRate_1 '$downloadRate_1'\nwmm_1 '$wmm_1'\nmacfilter_1 '$macfilter_1'\nurlfilter_1 '$urlfilter_1'\nqosmapset_1 '$qosmapset_1'\nieee80211w_1 '$ieee80211w_1'\nbssRate_1 '$bssRate_1'\nmgmtRate_1 '$mgmtRate_1'\nvlan_1 '$vlan_1'\nencryption_1 '$encryption_1'\nSSID_1 '$SSID_1'\nproxyarp_1 '$proxyarp_1'\ndisassoclowack_1 '$disassoclowack_1'\nrsnpreauth_1 '$rsnpreauth_1'\nrts_1 '$rts_1'\nisolate_1 '$isolate_1'\nforceDhcp_1 '$forceDhcp_1'\nftoverds_1 '$ftoverds_1'\nr1keyholder_1 '$r1keyholder_1'\nftpskgeneratelocal_1 '$ftpskgeneratelocal_1'\nmobilitydomain_1 '$mobilitydomain_1'\npmkr1push_1 '$pmkr1push_1'\nreassociationdeadline_1 '$reassociationdeadline_1'\nwnmsleepmode_1 '$wnmsleepmode_1'\nbsstransition_1 '$bsstransition_1'\npureg_1 '$pureg_1'\ndtimPeriod_1 '$dtimPeriod_1'\nbroadcast_1 '$broadcast_1'\ndisabled_1 '$disabled_1'\nuapsd_1 '$uapsd_1'\nrrm_1 '$rrm_1'\nmaxassoc_1 '$maxassoc_1'" >>"$file"
    fi

    local hs_1=$(get_uci_value "$res_1" "hs")
    local hs_0=$(get_uci_value "$res_0" "hs")

    if [ "$hs_0" -eq 1 ] || [ "$hs_1" -eq 1 ]; then
        awk '/config opennds '\'"$wlan_name"\''/,/^$|^config opennds/ && !/^config opennds '\'"$wlan_name"\''/' /etc/config/opennds | cut -d" " -f2- >>"$opnendsFile"
        while IFS= read -r line1; do
            check_opennds_config "$line1" "$wlan_name"
        done <"$opnendsFile" >>"result"
        rm -f "$opnendsFile"
    fi

    while IFS= read -r line1; do
        process_config_option "$line1" "$wlan_name"
    done <"$file" >>"result"
    rm -f "$file"
}

fetchAllSSID() {
    local file="data"
    local opnendsFile="openndsFile"
    local command=""
    rm -f result
    local model=$(cat /etc/model | cut -d"." -f1)
    if [ "$model" = "QN-H-245" ]; then
        command="cfg80211tool"
    else
        command="iwpriv"
    fi
    SSID_list=$(uci show wireless | grep -w "name" | cut -d"=" -f2 | cut -d"_" -f1 | cut -d"'" -f2- | uniq)
    for wlan_name in $SSID_list; do
        sleep 1s && compare_wireless_configs "$wlan_name"
    done
}

fetchAllSSID
