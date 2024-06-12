#!/bin/bash
sudo apt-get install -y apt-transport-https software-properties-common wget &&
sudo mkdir -p /etc/apt/keyrings/ &&
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null &&
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list &&
echo "Updates the list of available packages" &&
sudo apt-get -y update &&
sudo apt-get -y install grafana &&
echo "starting grafana service"
sudo systemctl start grafana-server &&
sudo systemctl enable grafana-server.service
