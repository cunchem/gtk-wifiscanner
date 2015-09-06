#! /bin/sh

wlan_interface="wlan0"  # may need to be changed on some configuration


if iwconfig mon0 2>&1 | grep -q "No such device"
then 
   echo "Starting monitoring interface"
    sudo airmon-ng start $wlan_interface
else
    echo "Monitoring interface mon0 already started"
fi




 #wlan_mgt.ssid !=\"\"

#sudo tshark -l -i mon0  -R "wlan.fc.type_subtype == 4  " -T fields -e frame.time    -e wlan.sa  -e wlan.da   -e radiotap.dbm_antsignal -e wlan_mgt.ssid -E separator=";"   | ./wifi_scanner_engine.rb
#sudo tshark -l -i mon0   -T fields -e frame.time    -e wlan.sa  -e wlan.da   -e radiotap.dbm_antsignal -e wlan_mgt.ssid -E separator=";"   | ./wifi_scanner_engine.rb
sudo tshark -l -i mon0  -R "wlan.fc.pwrmgt == 1 || wlan.fc.type_subtype == 4" -T fields -e frame.time    -e wlan.sa  -e wlan.da   -e radiotap.dbm_antsignal -e wlan_mgt.ssid -E separator=";" 2>/dev/null  | ./wifi_scanner_engine.rb
wlan.dmg.pwr_mgmt
